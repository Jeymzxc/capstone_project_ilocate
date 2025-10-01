import 'dart:async';
import 'package:flutter/material.dart';
import 'c_incident_respond.dart';
import 'models/alert.dart';
import 'models/maps_const.dart'; 
import 'database/firebase_db.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart' as polyline;

class AlertsRespond extends StatefulWidget {
  final Alert alert;
  final String deviceId;

  const AlertsRespond({
    super.key,
    required this.alert,
    required this.deviceId,
  });

  @override
  State<AlertsRespond> createState() => _AlertsRespondState();
}

class _AlertsRespondState extends State<AlertsRespond> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;
  bool _isMapReady = false;
  late Alert _currentAlert;

  LatLng? _rescuerLocation;

  final Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  Timer? _routeDebounceTimer;
  StreamSubscription<Position>? _positionStreamSubscription; 

  String? _routeDistance;
  String? _routeDuration;

  final Completer<GoogleMapController> _mapController = Completer();

  bool _isDetailsExpanded = true;

  // User details
  String? _fullName;
  String? _phone;
  String? _address;
  String? _dateOfBirth;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _currentAlert = widget.alert;
    _fetchUserDetails();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); 
    _routeDebounceTimer?.cancel();
    super.dispose();
  }

  /// Fetches user details from the database using deviceId
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
      debugPrint('Error fetching user details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get the Rescuer Current Location
  Future<void> _initializeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, 
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      if (mounted && _rescuerLocation == null) {
        final initialLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);
        setState(() {
          _rescuerLocation = initialLatLng;
        });
        await _createRoute(); 
        _zoomToFitMarkers();

        if (mounted) {
          setState(() {
            _isMapReady = true;
          });
        }
      }

    } catch (e) {
      debugPrint("⚠️ Could not get fast initial fix: $e");
      
    }
    
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation, 
      distanceFilter: 50, 
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {

      final newRescuerLocation = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _rescuerLocation = newRescuerLocation;
          });
        }

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

        // ✅ Debounced refresh (only runs if real movement detected)
        if (_routeDebounceTimer?.isActive ?? false) _routeDebounceTimer!.cancel();
        _routeDebounceTimer = Timer(const Duration(seconds: 30), () async {
          await _createRoute();
          _zoomToFitMarkers();
        });
    }, onError: (e) {
      debugPrint("❌ Location Stream Error: $e");
    });
  }
  
  // --- Route Calculation Logic ---

  Future<void> _createRoute() async {
    if (_rescuerLocation == null) {
      debugPrint("❌ Rescuer location is not available yet.");
      return;
    }

    try {
      final polyline.PolylinePoints polylinePoints = polyline.PolylinePoints(apiKey: GOOGLE_MAPS_API_KEY);

      polyline.RoutesApiRequest request = polyline.RoutesApiRequest(
        origin: polyline.PointLatLng(_rescuerLocation!.latitude, _rescuerLocation!.longitude,),
        destination: polyline.PointLatLng(_currentAlert.latitude, _currentAlert.longitude,),
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
        _currentAlert.latitude, 
        _currentAlert.longitude,
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
          LatLng(_currentAlert.latitude, _currentAlert.longitude),
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
        (_rescuerLocation!.latitude <= _currentAlert.latitude)
            ? _rescuerLocation!.latitude
            : _currentAlert.latitude,
        (_rescuerLocation!.longitude <= _currentAlert.longitude)
            ? _rescuerLocation!.longitude
            : _currentAlert.longitude,
      ),
      northeast: LatLng(
        (_rescuerLocation!.latitude > _currentAlert.latitude)
            ? _rescuerLocation!.latitude
            : _currentAlert.latitude,
        (_rescuerLocation!.longitude > _currentAlert.longitude)
            ? _rescuerLocation!.longitude
            : _currentAlert.longitude,
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

  /// Calculates age from date of birth string (yyyy-MM-dd)
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
    } catch (e) {
      return 'N/A';
    }
  }

  /// Builds a row with label and value
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ilocateRed,
        toolbarHeight: 90.0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
        ),
        title: const Text(
          'LOCATION TRACKING',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22.0),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),

      // Show loader if still fetching data OR waiting for first map fix
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
                // Google Map 
                Positioned.fill(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentAlert.latitude, _currentAlert.longitude),
                      zoom: 12,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("victim"),
                        position: LatLng(_currentAlert.latitude, _currentAlert.longitude),
                        infoWindow: InfoWindow(
                          title: _fullName ?? _currentAlert.rescueeName,
                          snippet: "Victim's Location",
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                      if (_rescuerLocation != null)
                        Marker(
                          markerId: const MarkerId("rescuer"),
                          position: _rescuerLocation!,
                          infoWindow: const InfoWindow(title: "Rescuer's Location"),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        ),
                    },
                    polylines: _polylines,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: _onMapCreated,
                  ),
                ),

                // Route Info Card (Top Overlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildRouteInfoCard(),
                  ),
                ),

                // Details Card and Confirm Button (Bottom Overlay)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Details Card
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'DETAILS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: ilocateRed),
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
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12.0)),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Container(
                                  padding: _isDetailsExpanded ? const EdgeInsets.all(16.0) : EdgeInsets.zero,
                                  child: _isDetailsExpanded
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Personal Details
                                            Text('PERSONAL DETAILS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                    color: ilocateRed)),
                                            const Divider(color: Colors.grey, height: 16, thickness: 1),
                                            _buildDetailRow(
                                                'Rescuee Name', _fullName ?? widget.alert.rescueeName),
                                            _buildDetailRow('Phone', _phone ?? 'N/A'),
                                            _buildDetailRow('Address', _address ?? 'N/A'),
                                            _buildDetailRow(
                                                'AGE',
                                                _dateOfBirth != null
                                                    ? _calculateAge(_dateOfBirth!)
                                                    : 'N/A'),
                                            _buildDetailRow('Sex', _sex ?? 'N/A'),
                                            const SizedBox(height: 16.0),

                                            // Alert Details
                                            Text('ALERT DETAILS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                    color: ilocateRed)),
                                            const Divider(color: Colors.grey, height: 16, thickness: 1),
                                            _buildDetailRow('Incident ID', widget.alert.incidentId),
                                            _buildDetailRow('Date', widget.alert.date),
                                            _buildDetailRow('Time', widget.alert.time),
                                            _buildDetailRow('Location', widget.alert.location),
                                            _buildDetailRow('Heart Rate', widget.alert.heartRate),
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
                      // Respond Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IncidentRespond(
                                    alert: widget.alert,
                                    deviceId: widget.deviceId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ilocateRed,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text(
                              'RESPOND',
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
  }
}
