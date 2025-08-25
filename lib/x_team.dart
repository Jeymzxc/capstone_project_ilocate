import 'package:flutter/material.dart';
import 'x_team_add.dart';
import 'x_team_rescue.dart';

class x_Team extends StatefulWidget {
  const x_Team({super.key});

  @override
  State<x_Team> createState() => _x_TeamState();
}

class _x_TeamState extends State<x_Team> {
  final Color ilocateRed = const Color(0xFFC70000);

  // A list to store the names of the rescue teams
  List<String> _groups = ['MDRRMO_Group1', 'MDRRMO_Group2'];

  // Function to remove a group from the list
  void _deleteGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
  }

  // Function to show the confirmation dialog with a more specific message
  Future<void> _showDeleteConfirmationDialog(int index) async {
    String groupName = _groups[index];
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
          content: Text(
            'Are you sure you want to delete the rescue team: "$groupName"? This action cannot be undone.',
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
                _deleteGroup(index); // Call the delete function
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

  // Function to add a new group from the x_teamAdd form
  void _addNewGroup(BuildContext context) async {
    final newTeamData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const x_teamAdd()),
    );

    // If new data is returned, add the new team name to the list
    if (newTeamData != null && newTeamData['teamName'] != null) {
      setState(() {
        _groups.add(newTeamData['teamName']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 120.0,
        backgroundColor: ilocateRed,
        title: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'MANAGE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
              Text(
                'RESCUE TEAM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0,
                ),
              ),
            ],
          ),
        ),
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
                Expanded(
                  // Use Expanded to allow the list to fill the available space
                  child: ListView.builder(
                    // The item count is now one more than the number of groups
                    itemCount: _groups.length + 1,
                    itemBuilder: (context, index) {
                      // Check if we are at the last item in the list
                      if (index == _groups.length) {
                        // This is the "add new group" button
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _addNewGroup(context),
                            borderRadius: BorderRadius.circular(12.0),
                            splashColor: Colors.grey.withOpacity(0.3),
                            // Updated: Increased opacity for a more visible highlight
                            highlightColor: Colors.grey.withOpacity(0.4),
                            child: Container(
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
                          ),
                        );
                      } else {
                        // This is a regular group container
                        String groupName = _groups[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            // All group containers should now have a working onTap function
                            onTap: (index == 0)
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TeamRescue()),
                                    );
                                  }
                                : () {
                                    // You can add logic for other groups here if needed
                                    // For now, it just provides the visual highlight
                                  },
                            borderRadius: BorderRadius.circular(12.0),
                            splashColor: Colors.grey.withOpacity(0.3),
                            highlightColor: Colors.grey.withOpacity(0.4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: ilocateRed, width: 2.0),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      groupName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Color(0xFFC70000), size: 28.0),
                                    onPressed: () {
                                      _showDeleteConfirmationDialog(index);
                                    },
                                  ),
                                ],
                              ),
                            ),
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
