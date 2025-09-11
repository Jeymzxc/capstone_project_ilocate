import 'package:flutter/material.dart';
import 'models/alert.dart';
import 'g_admin_navigation.dart';

class w_alertsNavigate extends StatelessWidget {
  final Alert alert;

  const w_alertsNavigate({super.key, required this.alert});

  final Color ilocateRed = const Color(0xFFC70000);

  // This function now navigates back to the AdminNavigationScreen
  void _markResolved(BuildContext context) {
    debugPrint("MARK RESOLVED button pressed for Incident ID: ${alert.incidentId}");
    // Navigate back to the main navigation screen and select the 'Alerts' tab (index 1)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminNavigationScreen(selectedIndex: 1)),
    );
  }

  void _pingRescuee() {
    debugPrint("PING button pressed for Incident ID: ${alert.incidentId}");
    // Add your ping logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ilocateRed,
        toolbarHeight: 90.0,
        leading: GestureDetector(
          // The back button should also navigate back to the main navigation screen
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminNavigationScreen(selectedIndex: 1)),
          ),
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
                                        // Now we can use the details from the full Alert object
                                        Text('RESCUEE NAME: ${alert.rescueeName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('INCIDENT ID: ${alert.incidentId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('DATE: ${alert.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('TIME: ${alert.time}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Now we can use the details from the full Alert object
                                        Text('LOCATION: ${alert.location}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('HEART RATE: ${alert.heartRate}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                onPressed: _pingRescuee,
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
                        onPressed: () => _markResolved(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ilocateRed,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Text(
                          'MARK RESOLVED',
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
