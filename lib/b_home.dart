import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ilocate/g_rescuer_navigation.dart';
import 'database/firebase_db.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final DatabaseService _databaseService = DatabaseService();
  int _sosNotificationCount = 0;
  String? _rescuerTeamName;

  static const LatLng _defaultPosition = LatLng(14.0230, 121.0930);

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _rescuerLocation;

  // For getting the rescuer Location 
  StreamSubscription<Position>? _positionStreamSubscription; 

  // For Streaming current incidents
  StreamSubscription<List<Map<String, dynamic>>>? _alertSubscription;

  StreamSubscription<dynamic>? _mapIncidentSubscription;



  @override
  void initState() {
    super.initState();
    _loadTeamIdAndStreamIncidents().then((_) {
      _initializeLocation(); 
    });
  }

   @override
  void dispose() {
    _positionStreamSubscription?.cancel(); 
    _alertSubscription?.cancel();
    _mapIncidentSubscription?.cancel();
    super.dispose();
  }

   

  Future<void> _loadTeamIdAndStreamIncidents() async {
    // Prevent reloading if already initialized
    if (_rescuerTeamName != null) return;

    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getString('teamsId');

    if (teamId != null) {
      final teamData = await _databaseService.getSingleTeam(teamId);
      if (mounted && teamData != null) {
        _rescuerTeamName = teamData['teamName'];
        await _subscribeToAlerts(_rescuerTeamName!);
      }
      if (_rescuerTeamName != null) {
        _alertSubscription = _databaseService
            .streamRescuerIncidents(_rescuerTeamName!)
            .listen((alertsData) {
          if (mounted) {
            setState(() {
              _sosNotificationCount = alertsData.length;
            });
          }
        });
      }
    }

    if (teamId != null) {
      _mapIncidentSubscription = 
        _databaseService.streamRescuerMapIncidents(_rescuerTeamName!).listen((incidents) async {
        final updatedMarkers = <Marker>{};

        for (var incident in incidents) {
          final devuid = incident["deviceId"];
          final lat = incident["value"]["latitude"];
          final lng = incident["value"]["longitude"];
          final hr = incident["value"]["heartRate"];

          final deviceInfo = await _databaseService.getDeviceInfoByDevuid(devuid);
          final fullname = deviceInfo?["fullname"] ?? "Unknown";
          final phone = deviceInfo?["phone"] ?? "N/A";

          updatedMarkers.add(
            Marker(
              markerId: MarkerId(devuid),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: fullname,
                snippet: "Heart Rate: $hr | Phone: $phone",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(LatLng(lat, lng), 12),
                );
              },
            ),
          );
        }

        // Add rescuer marker
        if (_rescuerLocation != null) {
          updatedMarkers.add(
            Marker(
              markerId: const MarkerId("rescuer"),
              position: _rescuerLocation!,
              infoWindow: const InfoWindow(title: "Rescuer's Location"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _markers
              ..clear()
              ..addAll(updatedMarkers);
          });
        }
      });
    }
  }

  // Stream-based location updates
  void _initializeLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, 
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (_rescuerTeamName != null) {
        await _databaseService.updateRescuerLocation(
          _rescuerTeamName,
          initialPosition.latitude,
          initialPosition.longitude,
        );
        debugPrint("📍 Initial location uploaded for $_rescuerTeamName");
      }

      final initialLatLng = LatLng(initialPosition.latitude, initialPosition.longitude);

      if (mounted) {
        setState(() {
          _rescuerLocation = initialLatLng;
          _markers.removeWhere((m) => m.markerId.value == "rescuer");
          _markers.add(
            Marker(
              markerId: const MarkerId("rescuer"),
              position: _rescuerLocation!,
              infoWindow: const InfoWindow(title: "Your Location"),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(initialLatLng, 12),
        );
      }
    } catch (e) {
      debugPrint("Could not get fast initial fix: $e");
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) async {
      final newLocation = LatLng(position.latitude, position.longitude);


      if (_rescuerTeamName != null) {
        debugPrint("📡 Sending location update for $_rescuerTeamName: "
        "Lat=${position.latitude}, Lng=${position.longitude}");

        await _databaseService.updateRescuerLocation(
          _rescuerTeamName,
          position.latitude,
          position.longitude,
        );

        debugPrint("✅ Successfully updated location to Firebase for $_rescuerTeamName");
      } else {
        debugPrint("⚠️ Skipped update: teamId is null");
      }
      
      // Only update if the location has changed significantly to reduce widget rebuilds
      if (_rescuerLocation == null || 
          Geolocator.distanceBetween(
              _rescuerLocation!.latitude, _rescuerLocation!.longitude,
              newLocation.latitude, newLocation.longitude) > 5) 
      {
        if (mounted) {
          setState(() {
            _rescuerLocation = newLocation;
            // Update rescuer marker only
            _markers.removeWhere((m) => m.markerId.value == "rescuer");
            _markers.add(
              Marker(
                markerId: const MarkerId("rescuer"),
                position: _rescuerLocation!,
                infoWindow: const InfoWindow(title: "Rescuer's Location"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
            );
          });
          
          // Optionally move camera to follow the rescuer (can be removed if map should stay static)
          _mapController?.animateCamera(
             CameraUpdate.newLatLng(newLocation),
          );
        }
      }
    }, onError: (e) {
      debugPrint("Location Stream Error: $e");
    });
  }

  Future<void> _subscribeToAlerts(String teamName) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic("rescuer_$teamName");
      debugPrint("📡 Subscribed to rescuer $teamName topic");
    } catch (e) {
      debugPrint("❌ Subscription failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _rescuerLocation ?? _defaultPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_rescuerLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_rescuerLocation!, 12),
                );
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          // SOS notification button
          Positioned(
            top: 16.0,
            left: 16.0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning_amber, size: 30, color: ilocateRed),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(initialIndex: 1),
                        ),
                      );
                    },
                  ),
                  if (_sosNotificationCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: ilocateRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          _sosNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.black),
        onPressed: () {
          if (_mapController != null && _rescuerLocation != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_rescuerLocation!, 12),
            );
          }
        },
      ),
    );
  }
}
