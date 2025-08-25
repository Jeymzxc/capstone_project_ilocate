import 'package:flutter/material.dart';

class Team extends StatelessWidget {
  const Team({super.key});

  final Color ilocateRed = const Color(0xFFC70000);

  // The list of team members is now a constant, as it will not change.
  final List<Map<String, String>> teamMembers = const [
    {'name': 'Juan D. Vera', 'role': 'Medic'},
    {'name': 'Jun Marcus J. Martinez', 'role': 'Coordinator'},
    {'name': 'Martin G. Hernandez', 'role': 'Search & Rescue'},
    {'name': 'Rolando K. Reyes', 'role': 'Search & Rescue'},
    {'name': 'Mario P. Paloma', 'role': 'Team Leader'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90.0,
        title: const Text(
          'RESCUE TEAM',
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
            child: Column(
              children: [
                const Icon(Icons.groups, size: 80.0, color: Color(0xFFC70000)),
                const SizedBox(height: 12.0),

                // 🟥 Boxed and centered group title
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: ilocateRed, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Center(
                          child: Text(
                            'MDRRMO_Group1',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: teamMembers.length,
                    itemBuilder: (context, index) {
                      final member = teamMembers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: ilocateRed, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              member['name']!,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              member['role']!,
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
