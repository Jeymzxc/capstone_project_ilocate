import 'package:flutter/material.dart';
import 'c_alerts_view.dart';
import 'c_alerts_respond.dart';
import 'c_alert_details.dart';

class Alerts extends StatefulWidget {
  final int selectedIndex;

  const Alerts({super.key, required this.selectedIndex});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  // Add a boolean flag to prevent multiple navigation pushes
  bool _isNavigating = false;

  final List<Alert> _alerts = [
    Alert(
      rescueeName: 'John Doe',
      incidentId: 'x32A12K',
      date: 'May 10, 2025',
      time: '5:30 AM',
      location: 'Lat 13.9563, Long 100.2018',
      heartRate: '90 BPM',
    ),
    Alert(
      rescueeName: 'Bill Amor',
      incidentId: 'b3AA1CA',
      date: 'May 10, 2025',
      time: '5:40 AM',
      location: 'Lat 13.9563, Long 100.2018',
      heartRate: '80 BPM',
    ),
  ];

  void _onViewPressed(Alert alert) {
    // Add a check to prevent multiple navigations
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsView(alert: alert),
      ),
    ).then((_) {
      // Reset the flag once navigation is complete
      setState(() {
        _isNavigating = false;
      });
    });
  }

  void _onRespondPressed(Alert alert) {
    // Add a check to prevent multiple navigations
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsRespond(alert: alert),
      ),
    ).then((_) {
      // Reset the flag once navigation is complete
      setState(() {
        _isNavigating = false;
      });
    });
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.builder(
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
                      Text(
                        'DETAILS:',
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
                              onPressed: _isNavigating ? null : () => _onViewPressed(alert),
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
                              onPressed: _isNavigating ? null : () => _onRespondPressed(alert),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ilocateRed,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('RESPOND'),
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
