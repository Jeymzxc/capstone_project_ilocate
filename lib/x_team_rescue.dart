import 'package:flutter/material.dart';
import 'x_team_member.dart'; // Import the x_teamMember.dart file

// The widget is now a StatefulWidget to manage the state of the team members.
class TeamRescue extends StatefulWidget {
  const TeamRescue({super.key});

  @override
  State<TeamRescue> createState() => _TeamRescueState();
}

class _TeamRescueState extends State<TeamRescue> {
  final Color ilocateRed = const Color(0xFFC70000);

  // The list of team members is no longer a constant and can be modified.
  final List<Map<String, String>> _teamMembers = [
    {'name': 'Juan D. Vera', 'role': 'Team Leader'}, // Corrected role
    {'name': 'Jun Marcus J. Martinez', 'role': 'Coordinator'},
    {'name': 'Martin G. Hernandez', 'role': 'Search & Rescue'},
    {'name': 'Rolando K. Reyes', 'role': 'Search & Rescue'},
    {'name': 'Mario P. Paloma', 'role': 'Medic'}, // Corrected role
  ];

  /// A function to handle the removal of a team member from the list.
  void _removeMember(int index) {
    setState(() {
      _teamMembers.removeAt(index);
    });
  }

  /// A function to show the confirmation dialog for deleting a team member.
  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          titlePadding: EdgeInsets.zero, // Remove default padding
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
                  'Confirm Deletion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ],
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this member from the team?',
            textAlign: TextAlign.center,
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
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text(
                'No',
                style: TextStyle(color: ilocateRed),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ilocateRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                _removeMember(index); // Call the delete function
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to navigate to the x_teamMember screen and add the new member.
  void _addMember() async {
    // Navigate to the x_teamMember screen and wait for a result.
    final newMemberData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const x_teamMember(),
      ),
    );

    // If data is returned (meaning the user pressed DONE), add it to the list.
    if (newMemberData != null) {
      setState(() {
        _teamMembers.add({
          'name': newMemberData['fullname'],
          'role': newMemberData['role'],
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This allows the default back button to show.
        automaticallyImplyLeading: true,
        leading: IconButton(
          // Changed the back button icon to a more modern arrow
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            // This will navigate back to the previous screen (x_Team.dart).
            Navigator.of(context).pop();
          },
        ),
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
                    // The item count is now one more than the number of members
                    itemCount: _teamMembers.length + 1,
                    itemBuilder: (context, index) {
                      // Check if we are at the last item in the list
                      if (index == _teamMembers.length) {
                        // This is the "add new member" button, now with InkWell for tapping
                        return InkWell(
                          onTap: _addMember,
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: ilocateRed, width: 2.0),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_circle,
                                color: ilocateRed,
                                size: 24.0,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // This is a regular team member container
                        final member = _teamMembers[index];
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
                              // Use Expanded to make the name take up available space
                              Expanded(
                                child: Text(
                                  member['name']!,
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Wrap the role and icon in a nested Row for proper alignment
                              Row(
                                children: [
                                  Text(
                                    member['role']!,
                                    textAlign: TextAlign.right, // Align the text to the right
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0), // Add spacing between the role and the icon
                                  // Button to remove the team member
                                  IconButton(
                                    icon: Icon(Icons.remove_circle, color: ilocateRed),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(index);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
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
