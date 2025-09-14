import 'package:flutter/material.dart';
import 'database/firebase_db.dart';

class Team extends StatefulWidget {
  const Team({super.key});

  @override
  State<Team> createState() => _TeamState();
}
  class _TeamState extends State<Team> {
    final Color ilocateRed = const Color(0xFFC70000);
    final DatabaseService _db = DatabaseService();

    String teamName = "";
    List<Map<String, dynamic>> members = [];
    bool isLoading = true;

    @override
    void initState() {
      super.initState();
      _loadTeamData();
    }

    Future<void> _loadTeamData() async {
      final teams = await _db.getTeams();
      if (teams.isNotEmpty) {
        final team = teams.first;
        final teamId = team['id'];
        final teamMembers = await _db.getTeamMembers(teamId);

        setState(() {
          teamName = team['teamName'] ?? "Unnamed Team";
          members = teamMembers;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }

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
            child: isLoading
                ? const CircularProgressIndicator(color: Color(0xFFC70000)) 
                : Column(
                    children: [
                      const Icon(Icons.groups, size: 80.0, color: Color(0xFFC70000)),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: ilocateRed, width: 2.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Center(
                                child: Text(
                                  teamName,
                                  style: const TextStyle(
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

                      // Display team members from Firebase
                      Expanded(
                        child: members.isEmpty
                            ? const Text("No members in this team.")
                            : ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  final member = members[index];
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
                                          member['fullname'] ?? "Unnamed",
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          member['role'] ?? "No role",
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