import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ilocate/g_rescuer_navigation.dart';
import 'models/hidden.dart'; 
import 'database/firebase_db.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as polyline;

class MarkResolved extends StatefulWidget {
  final String incidentId;
  final String deviceId;

  const MarkResolved({super.key, required this.incidentId, required this.deviceId});

  @override
  State<MarkResolved> createState() => _MarkResolvedState();
}

class _MarkResolvedState extends State<MarkResolved> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _db = DatabaseService();

  bool _isDetailsExpanded = true;
  bool _isLoading = true;
  bool _isMapReady = false;
  bool _isFollowingRescuer = false;

  // For route following and google maps calculation
  double _rescuerBearing = 0.0; 
  LatLng? _lastRescuerLocation;  



  // Map controller
  final Completer<GoogleMapController> _mapController = Completer();

  // Rescuer's real-time location
  LatLng? _rescuerLocation;
  LatLng? _victimLocation;

  Timer? _routeDebounceTimer;
  StreamSubscription<Position>? _positionStreamSubscription; 

  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  // State for route info display
  String? _routeDistance;
  String? _routeDuration;



  // User details
  String? _fullName;
  String? _phone;
  String? _address;
  String? _dateOfBirth;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getRescuerLocation();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); 
    _routeDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final userDetails = await _db.getDeviceInfoByDevuid(widget.deviceId);
      if (userDetails != null && mounted) {
        setState(() {
          _fullName = userDetails['fullname'];
          _phone = userDetails['phone'];
          _address = userDetails['address'];
          _dateOfBirth = userDetails['dateOfBirth'];
          _sex = userDetails['sex'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

  // Get Rescuer's Current Location (Phone Holder)
  Future<void> _getRescuerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    try {
      // --- Fast initial fix ---
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted && _rescuerLocation == null) {
        _rescuerLocation = LatLng(initialPosition.latitude, initialPosition.longitude);

        setState(() {}); // Update UI

        // Once we have rescuer location, create route and zoom
        await _createRoute();
        await _zoomToFitMarkers();
      }
    } catch (e) {
      debugPrint("⚠️ Could not get initial rescuer location: $e");
    }

    // --- Continuous updates ---
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 50,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      final newRescuerLocation = LatLng(position.latitude, position.longitude);

      if (_lastRescuerLocation != null) {
        _rescuerBearing = _calculateBearing(_lastRescuerLocation!, newRescuerLocation);
      }
      _lastRescuerLocation = newRescuerLocation;

      if (mounted) setState(() => _rescuerLocation = newRescuerLocation);

      // Animate camera if following rescuer
      if (_isFollowingRescuer && mounted) {
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _rescuerLocation!,
              zoom: 16,
              bearing: _rescuerBearing,
            ),
          ),
        );
      }

      // --- Off-route check ---
      if (_polylineCoordinates.isNotEmpty) {
        final nearestPoint = _polylineCoordinates.reduce((a, b) {
          final distA = Geolocator.distanceBetween(
            a.latitude, a.longitude,
            newRescuerLocation.latitude, newRescuerLocation.longitude,
          );
          final distB = Geolocator.distanceBetween(
            b.latitude, b.longitude,
            newRescuerLocation.latitude, newRescuerLocation.longitude,
          );
          return distA < distB ? a : b;
        });

        final deviation = Geolocator.distanceBetween(
          nearestPoint.latitude, nearestPoint.longitude,
          newRescuerLocation.latitude, newRescuerLocation.longitude,
        );

        if (deviation > 100) { 
          debugPrint("🚨 Off-route! Recalculating...");
          await _createRoute();
          _zoomToFitMarkers();
          return;
        }
      }

      // --- Debounced periodic route refresh ---
      _routeDebounceTimer?.cancel();
      _routeDebounceTimer = Timer(const Duration(seconds: 30), () async {
        await _createRoute();
        _zoomToFitMarkers();
      });

    }, onError: (e) {
      debugPrint("❌ Rescuer location stream error: $e");
    });
  }


  Future<void> _createRoute() async {
    if (_rescuerLocation == null || _victimLocation == null) {
      debugPrint("❌ Rescuer & Victim location is not available yet.");
      return;
    }

    try {
      final polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(apiKey: ROUTES_API_KEY);

      polyline.RoutesApiRequest request = polyline.RoutesApiRequest(
        origin: polyline.PointLatLng(_rescuerLocation!.latitude, _rescuerLocation!.longitude,),
        destination: polyline.PointLatLng(_victimLocation!.latitude, _victimLocation!.longitude,),
        travelMode: polyline.TravelMode.driving,
        routingPreference: polyline.RoutingPreference.trafficAware, 
      );

      polyline.RoutesApiResponse response = await polylinePoints.getRouteBetweenCoordinatesV2(
        request: request,
      );

      if (response.routes.isNotEmpty) {
        polyline.Route route = response.routes.first;

        // Format the distance and duration from the route object
        final String distance = route.distanceKm != null ? "${route.distanceKm!.toStringAsFixed(1)} km" : "N/A";
        final String duration = route.durationMinutes != null ? "${route.durationMinutes!.round()} min" : "N/A";

        debugPrint("🛣 Distance: $distance, ⏱ Duration: $duration");

        List<polyline.PointLatLng> points = route.polylinePoints ?? [];

        if (points.isNotEmpty) {
          final List<LatLng> routePoints =
              points.map((p) => LatLng(p.latitude, p.longitude)).toList();

          setState(() {
            _polylineCoordinates = routePoints;
            _polylines.clear();
            _polylines.add(Polyline(
              polylineId: const PolylineId("route"),
              color: Colors.blue,
              width: 5,
              points: _polylineCoordinates,
            ));
            _routeDistance = distance;
            _routeDuration = duration;
            _isMapReady = true;
             
          });

        } else {
          debugPrint("⚠️ No polyline points in this route.");
          _setFallbackRoute(distance: distance, duration: duration);
        }
      } else {
        debugPrint("⚠️ No routes found in API response.");
        _setFallbackRoute();
      }
    } catch (e) {
      debugPrint("❌ Error calling Routes API: $e");
      _setFallbackRoute();
    }
  }

  // Fallback: simple straight line polyline for API errors/no routes
  void _setFallbackRoute({String? distance, String? duration}) {
    // Calculate geodesic distance if the API didn't provide it
    double? fallbackDistanceKm;
    if (_rescuerLocation != null) {
      fallbackDistanceKm = Geolocator.distanceBetween(
        _rescuerLocation!.latitude, 
        _rescuerLocation!.longitude,
        _victimLocation!.latitude,
        _victimLocation!.longitude,
      ) / 1000;
    }
    
    // Use API result if available, otherwise use fallback calculation and mark it
    final finalDistance = distance ?? (fallbackDistanceKm != null ? "${fallbackDistanceKm.toStringAsFixed(1)} km (direct)" : "N/A");
    
    // Duration cannot be reliably calculated without the API
    final finalDuration = duration ?? 'N/A';

    if (mounted) {
      setState(() {
        _polylineCoordinates = [
          _rescuerLocation!,
          LatLng(_victimLocation!.latitude, _victimLocation!.longitude),
        ];
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId("route_fallback"),
          color: Colors.red.shade300, // Use a different color for fallback
          width: 3,
          points: _polylineCoordinates,
        ));
        
        _routeDistance = finalDistance;
        _routeDuration = finalDuration;
      });
    }
  }


  Future<void> _zoomToFitMarkers() async {
    if (_rescuerLocation == null) return;

    final GoogleMapController controller = await _mapController.future;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        (_rescuerLocation!.latitude <= _victimLocation!.latitude)
            ? _rescuerLocation!.latitude
            : _victimLocation!.latitude,
        (_rescuerLocation!.longitude <= _victimLocation!.longitude)
            ? _rescuerLocation!.longitude
            : _victimLocation!.longitude,
      ),
      northeast: LatLng(
        (_rescuerLocation!.latitude > _victimLocation!.latitude)
            ? _rescuerLocation!.latitude
            : _victimLocation!.latitude,
        (_rescuerLocation!.longitude > _victimLocation!.longitude)
            ? _rescuerLocation!.longitude
            : _victimLocation!.longitude,
      ),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }


  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
    }
  }

  // --- UI Helper Widgets ---

  // New widget to display route distance and time prominently
  Widget _buildRouteInfoCard() {
    if (_routeDistance == null || _routeDuration == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content horizontally
          children: [
            // Duration (Time)
            Icon(Icons.access_time, color: ilocateRed, size: 24),
            const SizedBox(width: 8.0),
            Text(
              _routeDuration!,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: ilocateRed,
              ),
            ),
            
            const SizedBox(width: 16.0),
            
            // Separator
            Container(width: 1, height: 20, color: Colors.grey[300]),

            const SizedBox(width: 16.0),

            // Distance
            Icon(Icons.directions_car, color: ilocateRed, size: 24),
            const SizedBox(width: 8.0),
            Text(
              _routeDistance!,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Calculate marker
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x) * 180 / pi; // Convert to degrees
    return (bearing + 360) % 360; // Normalize 0-360
  }

  String _calculateAge(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) return 'N/A';
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) return 'N/A';

      final today = DateTime.now();
      final birthDate = DateTime(year, month, day);
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$age";
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Future<void> _markResolved(String incidentId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _db.changeIncidentStatus(incidentId, 'resolved');

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showCustomDialog(
        title: 'Success',
        message: 'Incident $incidentId has been marked as resolved.',
        headerColor: Colors.green,
        icon: Icons.check_circle,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      _showCustomDialog(
        title: 'Error',
        message: 'Failed to mark incident as resolved.\nError: $e',
        headerColor: ilocateRed,
        icon: Icons.error,
        isSuccess: false,
      );
    }
  }

  // Reusable Show Dialog
  void _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
    bool isSuccess = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(0),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 4, color: headerColor),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: headerColor, size: 32),
                            const SizedBox(width: 8.0),
                            Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8.0),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // close the success dialog
                                if (isSuccess) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const MainNavigationScreen(initialIndex: 3)),
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
                                backgroundColor: headerColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

void _showMarkResolvedConfirmationDialog(BuildContext context, String incidentId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, color: ilocateRed),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, color: ilocateRed, size: 32),
                        const SizedBox(width: 8),
                        Text('STATUS UPDATE',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ilocateRed)),
                      ],
                    ),
                    const Divider(color: Colors.black26),
                    const SizedBox(height: 8),
                    const Text(
                      'Are you sure you want to mark this incident as resolved?',
                      style: TextStyle(fontSize: 14),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'This action cannot be undone.',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontStyle: FontStyle.italic,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: ilocateRed),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('NO', style: TextStyle(color: ilocateRed)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _markResolved(incidentId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ilocateRed,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('YES', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<Map<String, dynamic>?>(
          stream: _db.streamCombinedIncident(widget.incidentId, widget.deviceId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: ilocateRed,
                  title: const Text('LOCATION TRACKING'),
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC70000)),
                ),
              );
            }

            final incidentData = snapshot.data!;
            final incidentId = incidentData['id'] ?? widget.incidentId;
            final rescueeName = _fullName ?? incidentData['rescueeName'] ?? 'Unknown';

            final ttnData = incidentData['ttnData'] ?? {};
            final combinedValue = ttnData.isNotEmpty ? ttnData : Map<String, dynamic>.from(incidentData['value'] ?? {});

            final value = combinedValue.containsKey('value') ? Map<String, dynamic>.from(combinedValue['value'] ?? {}) : combinedValue;

            final heartRate = value['heartRate']?.toString() ?? 'N/A';
            final latitude = value['latitude']?.toString() ?? 'N/A';
            final longitude = value['longitude']?.toString() ?? 'N/A';

            if (value['latitude'] != null && value['longitude'] != null) {
              final newVictimLocation = LatLng(value['latitude'], value['longitude']);
              
              final distanceMoved = _victimLocation != null
                  ? Geolocator.distanceBetween(
                      _victimLocation!.latitude,
                      _victimLocation!.longitude,
                      newVictimLocation.latitude,
                      newVictimLocation.longitude,
                    )
                  : double.infinity;

              if (_victimLocation == null || distanceMoved > 50) {
                _victimLocation = newVictimLocation;

                _routeDebounceTimer?.cancel();
                _routeDebounceTimer = Timer(const Duration(seconds: 10), () {
                  if (_rescuerLocation != null) {
                    _createRoute();
                    _zoomToFitMarkers();
                  }
                });
              }
            }


            final location = 'Lat $latitude, Long $longitude';

            final ttnTimestamp = ttnData['timestamp'];
            DateTime? dateTime;

            if (ttnTimestamp != null) {
              if (ttnTimestamp is int) {
                dateTime = DateTime.fromMillisecondsSinceEpoch(ttnTimestamp);
              } else if (ttnTimestamp is String) {
                dateTime = DateTime.tryParse(ttnTimestamp);
              }
            }

            if (dateTime == null) {
              final incidentTimestamp =
                  incidentData['lastTimestamp'] ?? incidentData['firstTimestamp'];
              if (incidentTimestamp is int) {
                dateTime = DateTime.fromMillisecondsSinceEpoch(incidentTimestamp);
              } else if (incidentTimestamp is String) {
                dateTime = DateTime.tryParse(incidentTimestamp);
              }
            }

            final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
            final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: ilocateRed,
                toolbarHeight: 90.0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigationScreen(initialIndex: 3),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                title: const Text(
                  'LOCATION TRACKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                  ),
                ),
                centerTitle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              ),
              body: (_isLoading || !_isMapReady)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: ilocateRed),
                        const SizedBox(height: 16),
                        Text(
                          "Calculating location...",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: ilocateRed,
                          ),
                        ),
                      ],
                    ),
                  )

              : Stack(
                children: [
                  // Map placeholder
                  Positioned.fill(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(value['latitude'], value['longitude']),
                        zoom: 12,
                      ),
                      onMapCreated: _onMapCreated,
                      onCameraMoveStarted: () {
                        _isFollowingRescuer = false; 
                      },
                      polylines: _polylines,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      markers: {
                        if (_rescuerLocation != null)
                          Marker(
                            markerId: const MarkerId('rescuer'),
                            position: _rescuerLocation!,
                            infoWindow: const InfoWindow(title: "Rescuer's Location"),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                            rotation: _rescuerBearing, 
                            anchor: const Offset(0.5, 0.5),
                          ),
                        if (value['latitude'] != null && value['longitude'] != null)
                          Marker(
                            markerId: const MarkerId('incident'),
                            position: LatLng(value['latitude'], value['longitude']),
                            infoWindow:  InfoWindow(
                              title: _fullName ?? rescueeName,
                              snippet: "Victim's Location",
                              ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          ),
                      },
                    ),
                  ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildRouteInfoCard(),
                  ),
                ),
                Positioned(
                  bottom: 180,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "recenterBtn",
                        backgroundColor: Colors.white,
                        onPressed: () async {
                          if (_rescuerLocation != null) {
                            _isFollowingRescuer = true;

                            final GoogleMapController controller = await _mapController.future;
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: _rescuerLocation!,
                                  zoom: 16,
                                  bearing: _rescuerBearing,
                                ),
                              ),
                            );
                          }
                        },
                        elevation: 4,
                        child: Transform.rotate(
                          angle: _rescuerBearing * pi / 180,
                          child: Icon(Icons.navigation, color: ilocateRed),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Recenter",
                        style: TextStyle(
                          color: ilocateRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),



                  // Bottom Card with Details
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isDetailsExpanded = !_isDetailsExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'DETAILS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: ilocateRed,
                                        ),
                                      ),
                                      Icon(
                                        _isDetailsExpanded
                                            ? Icons.keyboard_arrow_down
                                            : Icons.keyboard_arrow_up,
                                        color: ilocateRed,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12.0),
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    padding: _isDetailsExpanded
                                        ? const EdgeInsets.all(16.0)
                                        : EdgeInsets.zero,
                                    child: _isDetailsExpanded
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'PERSONAL DETAILS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                  color: ilocateRed,
                                                ),
                                              ),
                                              const Divider(color: Colors.grey, height: 16, thickness: 1),
                                              _buildDetailRow( 'Rescuee Name', rescueeName),
                                              _buildDetailRow('Phone', _phone ?? 'N/A'),
                                              _buildDetailRow('Address', _address ?? 'N/A'),
                                              _buildDetailRow(
                                                'Age',
                                                _dateOfBirth != null
                                                    ? _calculateAge(_dateOfBirth!)
                                                    : 'N/A',
                                              ),
                                              _buildDetailRow('Sex', _sex ?? 'N/A'),
                                              const SizedBox(height: 16.0),
                                              Text(
                                                'ALERT DETAILS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                  color: ilocateRed,
                                                ),
                                              ),
                                              const Divider(
                                                color: Colors.grey,
                                                height: 16,
                                                thickness: 1,
                                              ),
                                              _buildDetailRow('Incident ID', incidentId),
                                              _buildDetailRow('Date', date),
                                              _buildDetailRow('Time', time),
                                              _buildDetailRow('Location', location),
                                              _buildDetailRow('Heart Rate', heartRate),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showMarkResolvedConfirmationDialog(
                                  context, incidentId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ilocateRed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text(
                                'MARK RESOLVED',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFC70000)),
              ),
            ),
          ),
      ],
    );
  }
}