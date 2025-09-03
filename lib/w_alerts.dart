import 'package:flutter/material.dart';
import 'c_alert_details.dart';
import 'w_alerts_assign.dart';

// This is a placeholder for the AlertsRespond screen.
// You will replace this with the actual file later.
class AlertsRespond extends StatelessWidget {
  final Alert alert;
  const AlertsRespond({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respond to Alert')),
      body: Center(child: Text('Responding to alert: ${alert.incidentId}')),
    );
  }
}

class AlertsView extends StatelessWidget {
  final Alert alert;

  const AlertsView({super.key, required this.alert});

  final Color ilocateRed = const Color(0xFFC70000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ilocateRed,
        toolbarHeight: 90.0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context), // Navigates back to the previous screen
          child: const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
          ),
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
      body: Stack(
        children: [
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
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DETAILS:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: ilocateRed),
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
                              const SizedBox(height: 48.0),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: SizedBox(
                              width: 120,
                              child: OutlinedButton(
                                onPressed: () {
                                  // No functionality yet, just a debug print
                                  debugPrint("PING button pressed for Incident ID: ${alert.incidentId}");
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: ilocateRed, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                  ),
                                ),
                                child: Text(
                                  'PING',
                                  style: TextStyle(
                                    color: ilocateRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context), // Navigates back to the previous screen
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Renamed the main class from "Alerts" to "wAlerts"
class wAlerts extends StatefulWidget {
  // Removed the 'selectedIndex' parameter from the class
  const wAlerts({super.key});

  @override
  State<wAlerts> createState() => _wAlertsState();
}

class _wAlertsState extends State<wAlerts> {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsView(alert: alert),
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