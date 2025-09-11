import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/alert.dart';
import 'database/firebase_db.dart';

class AlertsView extends StatefulWidget {
  final Alert alert;
  final String deviceId;
  final Function(Alert) onUpdate;

  const AlertsView({
    super.key,
    required this.alert,
    required this.deviceId,
    required this.onUpdate,
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

  // New state variables for user credentials
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
  }

  // Fetches user details from the database using the deviceId.
  Future<void> _fetchUserDetails() async {
    setState(() => _isLoading = true);
    try {
      // Use the provided deviceId to get user info from the database
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
      print('Error fetching user details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pingLatestData() async {
    setState(() => _isLoading = true);

    try {
      final latestData = await _db.getLatestDeviceData(widget.deviceId);

      if (latestData != null) {
        final value = latestData['value'] as Map<dynamic, dynamic>? ?? {};
        final timestamp = latestData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;

        final newAlert = Alert(
          rescueeName: _currentAlert.rescueeName,
          incidentId: _currentAlert.incidentId,
          deviceId: _currentAlert.deviceId,
          date: DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp)),
          time: DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp)),
          location: 'Lat ${value['latitude'] ?? 'N/A'}, Long ${value['longitude'] ?? 'N/A'}',
          heartRate: '${value['heartRate'] ?? 'N/A'} BPM',
        );

        setState(() {
          _currentAlert = newAlert;
        });

        // Call the callback to update the parent widget
        widget.onUpdate(newAlert);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Latest Location: Lat ${value['latitude']}, Lng ${value['longitude']}",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No latest data found for device."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching latest data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Helper widget to build a key-value pair row.
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ilocateRed),
            )
          : Stack(
              children: [
                // Map Placeholder - This is what you will replace
                Positioned.fill(
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Text(
                        'Map will be displayed here',
                        style: TextStyle(fontSize: 18.0, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Combined Details Card
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
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: ilocateRed),
                                    ),
                                    Icon(
                                      _isDetailsExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
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
                                            // Personal Details Section
                                            Text(
                                              'PERSONAL DETAILS',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: ilocateRed),
                                            ),
                                            const Divider(color: Colors.grey, height: 16, thickness: 1),
                                            _buildDetailRow('Rescuee Name', _fullName ?? _currentAlert.rescueeName),
                                            _buildDetailRow('Phone', _phone ?? 'N/A'),
                                            _buildDetailRow('Address', _address ?? 'N/A'),
                                            _buildDetailRow('Date of Birth', _dateOfBirth ?? 'N/A'),
                                            _buildDetailRow('Sex', _sex ?? 'N/A'),
                                            const SizedBox(height: 16.0),
                                            // Alert Details Section
                                            Text(
                                              'ALERT DETAILS',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: ilocateRed),
                                            ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _pingLatestData,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: ilocateRed, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ilocateRed,
                                    ),
                                  )
                                : Text(
                                    'PING LOCATION',
                                    style: TextStyle(
                                      color: ilocateRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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