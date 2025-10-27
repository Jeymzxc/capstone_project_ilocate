import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'database/firebase_db.dart';
import 'g_admin_navigation.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final DatabaseService _databaseService = DatabaseService();
  int _sosNotificationCount = 0;

  static const LatLng _initialPosition = LatLng(14.0230, 121.0930);
  LatLng? _lastMarkerPosition;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  StreamSubscription<List<Map<String, dynamic>>>? _pendingSubscription;
  StreamSubscription<Map<String, dynamic>>? _rescuerLocationSub;
  

  @override
    void initState() {
      super.initState();
      _subscribeToAlerts();
      _listenToPendingIncidents();
      _listenToRescuerLocations(); 
    }

    // Listen to pending distress incidents
    void _listenToPendingIncidents() {
      _pendingSubscription = _databaseService.streamPendingIncidents().listen((incidents) async {
        if (!mounted) return;

        setState(() {
          _sosNotificationCount = incidents.length;
        });

        final incidentMarkers = <Marker>{};

        for (var incident in incidents) {
          final devuid = incident["deviceId"];
          final lat = incident["value"]["latitude"];
          final lng = incident["value"]["longitude"];
          final hr = incident["value"]["heartRate"];

          final deviceInfo = await _databaseService.getDeviceInfoByDevuid(devuid);
          final fullname = deviceInfo?["fullname"] ?? "Unknown";
          final phone = deviceInfo?["phone"] ?? "N/A";

          incidentMarkers.add(
            Marker(
              markerId: MarkerId('incident_$devuid'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: fullname,
                snippet: "Heart Rate: $hr | Phone: $phone",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () {
                if (_mapController != null) {
                  _lastMarkerPosition = LatLng(lat, lng);
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
                  );
                }
              },
            ),
          );
        }

        // Merge with rescuer markers (if any)
        setState(() {
          _markers.removeWhere((m) => m.markerId.value.startsWith('incident_'));
          _markers.addAll(incidentMarkers);
        });
      });
    }

    // Listen to rescuer locations
    void _listenToRescuerLocations() {
      _rescuerLocationSub = _databaseService.streamRescuerLocations().listen((locations) {
        if (!mounted) return;

        final rescuerMarkers = <Marker>{};

        locations.forEach((teamName, value) {
          final lat = value['latitude']?.toDouble();
          final lng = value['longitude']?.toDouble();
          final status = value['status'];
          final lastStatusChange = value['lastStatusChange'];

          if (lat == null || lng == null) return;

          final bool isActive = status == 'active';
          final markerColor = isActive ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueYellow;

          // Show "Last Active" only if inactive
          String snippet;
          if (isActive) {
            snippet = '🟢 Active';
          } else {
            String lastActive = '';
            if (lastStatusChange != null) {
              final t = DateTime.fromMillisecondsSinceEpoch(lastStatusChange);
              final formattedDate = DateFormat('MMMM d, yyyy h:mm a').format(t);
              lastActive = ' | Last Active: $formattedDate';
            }
            snippet = '🔴 Inactive$lastActive';
          }

          rescuerMarkers.add(
            Marker(
              markerId: MarkerId('rescuer_$teamName'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: 'Team $teamName',
                snippet: snippet,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            ),
          );
        });

        setState(() {
          _markers.removeWhere((m) => m.markerId.value.startsWith('rescuer_'));
          _markers.addAll(rescuerMarkers);
        });
      });
    }


    // Subscribe to FCM distress alerts
    Future<void> _subscribeToAlerts() async {
      try {
        await FirebaseMessaging.instance.subscribeToTopic("distressAlerts");
        debugPrint("📡 Admin subscribed to distressAlerts topic");
      } catch (e) {
        debugPrint("❌ FCM subscription failed: $e");
      }
    }

    @override
    void dispose() {
      _pendingSubscription?.cancel();
      _rescuerLocationSub?.cancel();
      _mapController = null;
      super.dispose();
    }

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      body: Stack(
        children: [
          // 🗺 Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          // 🚨 SOS Notification Button
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
                    icon: const Icon(Icons.warning_amber,
                        size: 30, color: ilocateRed),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminNavigationScreen(selectedIndex: 1),
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
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
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

      // Button to recenter map
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.black),
        onPressed: () {
          if (_mapController != null && _lastMarkerPosition != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(_lastMarkerPosition!, 12),
            );
          }
        },
      ),
    );
  }
}
