import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';
import 'models/alert.dart';
import 'w_alerts_assign.dart';
import 'w_alerts_view.dart'; 

class wAlerts extends StatefulWidget {
  const wAlerts({super.key});

  @override
  State<wAlerts> createState() => _wAlertsState();
}

class _wAlertsState extends State<wAlerts> {
  final DatabaseService _databaseService = DatabaseService();
  List<Alert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {
    try {
      final alertsData = await _databaseService.streamTtnDistressData().first;
      await _updateAlertsList(alertsData);
    } catch (e) {
      print('Error fetching initial data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAlertsList(List<Map<String, dynamic>> alertsData) async {
    List<Alert> newAlerts = [];
    for (var alertData in alertsData) {
      final incidentId = alertData['id'];
      final deviceId = alertData['deviceId'] ?? '';
      final value = alertData['value'] as Map<dynamic, dynamic>? ?? {};

      final heartRate = value['heartRate']?.toString() ?? 'N/A';
      final latitude = value['latitude']?.toString() ?? 'N/A';
      final longitude = value['longitude']?.toString() ?? 'N/A';
      final timestamp = alertData['timestamp'];
      DateTime? dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.tryParse(timestamp);
      }

      final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
      final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';

      final deviceSnapshot = await _databaseService.getDeviceInfoByDevuid(deviceId);
      final rescueeName = deviceSnapshot?['fullname'] ?? 'Unknown';

      newAlerts.add(Alert(
        rescueeName: rescueeName,
        incidentId: incidentId ?? '',
        deviceId: deviceId,
        date: date,
        time: time,
        location: 'Lat $latitude, Long $longitude',
        heartRate: '$heartRate BPM',
      ));
    }
    setState(() {
      _alerts = newAlerts;
    });
  }

  void _onViewPressed(Alert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsView(
          alert: alert,
          deviceId: alert.deviceId,
          onUpdate: (updatedAlert) {
            setState(() {
              final index = _alerts.indexWhere((a) => a.incidentId == updatedAlert.incidentId);
              if (index != -1) {
                _alerts[index] = updatedAlert;
              }
            });
          },
        ),
      ),
    );
  }

  void _onAssignPressed(Alert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => wAlertsAssign(alert: alert),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90.0,
        title: const Text(
          'SOS ALERTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: ilocateRed,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ilocateRed))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _alerts.isEmpty
                      ? const Center(child: Text('No active SOS alerts.'))
                      : ListView.builder(
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: ilocateRed, width: 2.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ALERT DETAILS:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: ilocateRed,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'RESCUEE NAME: ${alert.rescueeName}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'INCIDENT ID: ${alert.incidentId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'DATE: ${alert.date}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'TIME: ${alert.time}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'LOCATION: ${alert.location}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              'HEART RATE: ${alert.heartRate}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: OutlinedButton(
                                          onPressed: () => _onViewPressed(alert),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: ilocateRed),
                                            foregroundColor: ilocateRed,
                                          ),
                                          child: const Text('VIEW'),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      SizedBox(
                                        width: 120,
                                        child: ElevatedButton(
                                          onPressed: () => _onAssignPressed(alert),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ilocateRed,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('ASSIGN'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
    );
  }
}
