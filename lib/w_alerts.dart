import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';
import 'models/alert.dart';
import 'w_alerts_assign.dart';
import 'w_alerts_view.dart';
import 'dart:async';

class wAlerts extends StatefulWidget {
  const wAlerts({super.key});

  @override
  State<wAlerts> createState() => _wAlertsState();
}

class _wAlertsState extends State<wAlerts> {
  final DatabaseService _databaseService = DatabaseService();

  StreamSubscription<List<Map<String, dynamic>>>? _ttnSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to TTN distress alerts
   _ttnSubscription = _databaseService.streamTtnDistressData().listen((alerts) async {
      for (var alert in alerts) {
        try {
   
          await _databaseService.createIncident(alert, '');
        } catch (e) {
          print("Error processing incoming alert for device ${alert['deviceId']}: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _ttnSubscription?.cancel();
    super.dispose();
  }

  void _onViewPressed(Alert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsView(
          alert: alert,
          deviceId: alert.deviceId,
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

  Future<void> _cancelIncident(String incidentId) async {
    await _databaseService.changeIncidentStatus(incidentId, "cancelled");
  }


  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    const Color ilocateRed = Color(0xFFC70000);
    final deviceId = incident['deviceId'] ?? '';
    final value = Map<String, dynamic>.from(incident['value'] ?? {});
    final heartRate = value['heartRate']?.toString() ?? 'N/A';
    final latitude = value['latitude']?.toString() ?? 'N/A';
    final longitude = value['longitude']?.toString() ?? 'N/A';

    // Use lastTimestamp or firstTimestamp
    final timestamp = incident['lastTimestamp'] ?? incident['firstTimestamp'];
    DateTime? dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp);
    }

    final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
    final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';

    // Build a FutureBuilder that fetches device/user info so we can show rescueeName
    return FutureBuilder<Map<String, dynamic>?>(
      future: _databaseService.getDeviceInfoByDevuid(deviceId),
      builder: (context, snapshot) {
        final deviceInfo = snapshot.data;
        final rescueeName = deviceInfo?['fullname'] ?? 'Unknown';

        final alertModel = Alert(
          rescueeName: rescueeName,
          incidentId: incident['id'] ?? incident['key'],
          deviceId: deviceId,
          date: date,
          time: time,
          location: 'Lat $latitude, Long $longitude',
          heartRate: '$heartRate BPM',
        );

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
                        Text('RESCUEE NAME: ${alertModel.rescueeName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                        Text('INCIDENT ID: ${alertModel.incidentId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                        Text('DATE: ${alertModel.date}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                        Text('TIME: ${alertModel.time}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOCATION: ${alertModel.location}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                        Text('HEART RATE: ${alertModel.heartRate}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelConfirmationDialog(incident['id']),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ilocateRed),
                        foregroundColor: ilocateRed,
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _onViewPressed(alertModel),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: ilocateRed),
                        foregroundColor: ilocateRed,
                      ),
                      child: const Text('VIEW', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _onAssignPressed(alertModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ilocateRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ASSIGN', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Reusable cancel confirmation dialog (kept similar to your previous)
  Future<void> _showCancelConfirmationDialog(String incidentId) async {
    const Color ilocateRed = Color(0xFFC70000);
    bool isCancelling = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Stack(
              children: [
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  titlePadding: EdgeInsets.zero,
                  title: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: ilocateRed,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Confirm Cancellation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Are you sure you want to cancel the alert for this incident?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.0),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: <Widget>[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: ilocateRed, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: isCancelling ? null : () => Navigator.of(context).pop(),
                      child: Text('No', style: TextStyle(color: isCancelling ? Colors.grey : ilocateRed)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ilocateRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: isCancelling
                          ? null
                          : () async {
                              setStateDialog(() => isCancelling = true);
                              try {
                                await _cancelIncident(incidentId);
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                 _showCustomDialog(
                                  title: 'Success',
                                  message: 'Incident cancelled successfully',
                                  headerColor: ilocateRed,
                                  icon: Icons.check_circle_rounded,
                                  isSuccess: false, 
                                );
                              } catch (e) {
                                if (!mounted) return;
                                Navigator.of(context).pop();
                                _showCustomDialog(
                                  title: 'Error',
                                  message: 'Failed to cancel incident',
                                  headerColor: ilocateRed,
                                  icon: Icons.error_outline_rounded,
                                );
                              } finally {
                                setStateDialog(() => isCancelling = false);
                              }
                            },
                      child: const Text('Yes', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                if (isCancelling)
                  Container(
                    color: Colors.black54,
                    child:  Center(child: CircularProgressIndicator(color: ilocateRed)),
                  ),
              ],
            );
          },
        );
      },
    );
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
                                Navigator.of(context).pop();
                                if (isSuccess) {
                                  Navigator.pop(context, true);
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
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _databaseService.streamPendingIncidents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: ilocateRed,));
              }

              final incidents = snapshot.data ?? [];

              if (incidents.isEmpty) {
                return const Center(child: Text('No active SOS alerts.'));
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return _buildIncidentCard(incident);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
