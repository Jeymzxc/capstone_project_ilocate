import 'package:flutter/material.dart';
import 'models/alert.dart';
import 'database/firebase_db.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertsView extends StatefulWidget {
  final Alert alert;
  final String deviceId;

  const AlertsView({
    super.key,
    required this.alert,
    required this.deviceId,
  });

  @override
  State<AlertsView> createState() => _AlertsViewState();
}

class _AlertsViewState extends State<AlertsView> {
  final Color ilocateRed = const Color(0xFFC70000);
  bool _isLoading = false;
  final DatabaseService _db = DatabaseService();
  late Alert _currentAlert;

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
    _fetchUserDetails(); // Load personal details from database
  }

  /// Fetches user details from the database using deviceId
  Future<void> _fetchUserDetails() async {
    setState(() => _isLoading = true);
    try {
      final userDetails = await _db.getDeviceInfoByDevuid(widget.deviceId);
      if (userDetails != null) {
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
      setState(() => _isLoading = false);
    }
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

  /// Builds a row with label and value for the details section
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          )
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ilocateRed))
          : Stack(
              children: [
                // Map Placeholder 
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
                    },
                    myLocationEnabled: false, 
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                                                'Rescuee Name', _fullName ?? _currentAlert.rescueeName),
                                            _buildDetailRow('Phone', _phone ?? 'N/A'),
                                            _buildDetailRow('Address', _address ?? 'N/A'),
                                            _buildDetailRow(
                                                'AGE', _dateOfBirth != null ? _calculateAge(_dateOfBirth!) : 'N/A'),
                                            _buildDetailRow('Sex', _sex ?? 'N/A'),
                                            const SizedBox(height: 16.0),
                                            // Alert Details
                                            Text('ALERT DETAILS',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                    color: ilocateRed)),
                                            const Divider(color: Colors.grey, height: 16, thickness: 1),
                                            _buildDetailRow('Incident ID', _currentAlert.incidentId),
                                            _buildDetailRow('Date', _currentAlert.date),
                                            _buildDetailRow('Time', _currentAlert.time),
                                            _buildDetailRow('Location', _currentAlert.location),
                                            _buildDetailRow('Heart Rate', _currentAlert.heartRate),
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
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ilocateRed,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text(
                              'CONFIRM',
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
