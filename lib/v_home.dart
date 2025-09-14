import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // Placeholder for the number of ongoing alerts
  final int _sosNotificationCount = 2;

  // This function is now empty as the functionality was removed per your request
  void _onSosButtonPressed() {}

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Map will be displayed here.',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ),
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
                    color: Colors.black.withOpacity(0.2),
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
                    onPressed: _onSosButtonPressed,
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
    );
  }
}