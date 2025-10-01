import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database/firebase_db.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final DatabaseService _databaseService = DatabaseService();
  final int _sosNotificationCount = 2;

  static const LatLng _initialPosition = LatLng(14.0230, 121.0930);
  LatLng? _lastMarkerPosition;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    // Subscribe to distress data
    _databaseService.streamAdminIncidents().listen((victims) async {
      final updatedMarkers = <Marker>{};

      for (var victim in victims) {
        final devuid = victim["deviceId"];
        final lat = victim["value"]["latitude"];
        final lng = victim["value"]["longitude"];
        final hr = victim["value"]["heartRate"];

        // Fetch wearer info
        final deviceInfo = await _databaseService.getDeviceInfoByDevuid(devuid);

        final fullname = deviceInfo?["fullname"] ?? "Unknown";
        final phone = deviceInfo?["phone"] ?? "N/A";

        updatedMarkers.add(
          Marker(
            markerId: MarkerId(devuid),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: fullname, // Wearer’s full name
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

      // Update markers on the map
      if (mounted) {
        setState(() {
          _markers
            ..clear()
            ..addAll(updatedMarkers);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          // SOS notification button (top left)
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
                    onPressed: () =>
                        debugPrint("SOS Button pressed by Admin"),
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
      // Button to reset the camera position
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
