import 'package:flutter/material.dart';
import 'x_team_add.dart';
import 'x_team_rescue.dart';
import 'database/firebase_db.dart';

class x_Team extends StatefulWidget {
  const x_Team({super.key});

  @override
  State<x_Team> createState() => _x_TeamState();
}

class _x_TeamState extends State<x_Team> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _databaseService = DatabaseService();

  // A Future to hold the list of teams
   late Future<List<Map<String, dynamic>>> _teamsFuture;
   bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Fetch teams only once when the widget is created
    _teamsFuture = _databaseService.getTeams();
  }

  // Refreshes the list of teams from the database
  void _refreshTeams() {
    setState(() {
      _teamsFuture = _databaseService.getTeams();
    });
  }

  // Navigates to the add team page and refreshes the list on return
  void _addNewGroup(BuildContext context) async {
    final newTeamData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const x_teamAdd()),
    );

    if (newTeamData != null && 
        newTeamData is Map && 
        newTeamData['success'] == true) {
      _refreshTeams();
    }
  }

  // Reusable Show Dialog
  Future<void> _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
    bool isSuccess = false,
  }) {
    return showDialog<void>(
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

  // Show delete confirmation dialog 
  Future<void> _showDeleteConfirmationDialog(
      String teamId, String teamName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Added: StatefulBuilder to manage deletion loader inside dialog
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
                    'Are you sure you want to delete the rescue team: "$teamName"? This action cannot be undone.',
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () async {
                        setStateDialog(() => _isDeleting = true); 
                        try {
                          await _databaseService.deleteTeam(teamId);
                          setStateDialog(() => _isDeleting = false); 
                          if (!context.mounted) return;
                          Navigator.of(context).pop(); 
                          _showCustomDialog(
                            title: 'Success!',
                            message: 'Successfully deleted.',
                            headerColor: Colors.green,
                            icon: Icons.check_circle_outline,
                          );
                          _refreshTeams();
                        } catch (e) {
                          setStateDialog(() => _isDeleting = false); 
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          _showCustomDialog(
                            title: 'Error!',
                            message: 'Failed to delete team. Please try again.',
                            headerColor: Colors.red,
                            icon: Icons.error_outline,
                          );
                          debugPrint('Error deleting team: $e');
                        }
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

                // Added: red loader overlay during deletion
                if (_isDeleting)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(color: ilocateRed),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Builds the "Add New Group" button
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _addNewGroup(context),
        borderRadius: BorderRadius.circular(12.0),
        splashColor: Colors.grey.withValues(alpha: 0.3),
        highlightColor: Colors.grey.withValues(alpha: 0.4),
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
  }

  // Builds a single team card
  Widget _buildTeamCard(Map<String, dynamic> team) {
    final teamId = team['id'] as String;
    final teamName = team['teamName'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamRescue(teamId: teamId, teamName: teamName), 
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        splashColor: Colors.grey.withValues(alpha: 0.3),
        highlightColor: Colors.grey.withValues(alpha: 0.4),
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
                  teamName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle,
                    color: Color(0xFFC70000), size: 28.0),
                onPressed: () {
                  _showDeleteConfirmationDialog(teamId, teamName);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _teamsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFC70000)));
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final teams = snapshot.data ?? [];

                      // Sort teams Alphabetically and Numerically
                      teams.sort((a, b) {
                        final nameA = a['teamName']?.toString().toLowerCase() ?? '';
                        final nameB = b['teamName']?.toString().toLowerCase() ?? '';
                        
                        // First sort alphabetically by the text part
                        final textCompare = nameA.compareTo(nameB);
                        if (textCompare != 0) return textCompare;
                        
                        // Then by number if text is the same
                        final numA = int.tryParse(nameA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        final numB = int.tryParse(nameB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                        return numA.compareTo(numB);
                      });

                      return ListView.builder(
                        itemCount: teams.length + 1,
                        itemBuilder: (context, index) {
                          if (index == teams.length) {
                            return _buildAddButton();
                          } else {
                            return _buildTeamCard(teams[index]);
                          }
                        },
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