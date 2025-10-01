import 'package:flutter/material.dart';
import 'x_team_member.dart';
import 'database/firebase_db.dart';

class TeamRescue extends StatefulWidget {
  final String teamId;
  final String teamName;
  const TeamRescue({super.key, required this.teamId, required this.teamName});

  @override
  State<TeamRescue> createState() => _TeamRescueState();
}

class _TeamRescueState extends State<TeamRescue> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _databaseService = DatabaseService();

  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _hasTeamLeader = false; 

  @override
  void initState() {
    super.initState();
    _loadTeamMembers(); 
  }

  Future<void> _loadTeamMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await _databaseService.getTeamMembers(widget.teamId);

      members.sort((a, b) {
        bool aIsLeader = a['role'] == 'Team Leader';
        bool bIsLeader = b['role'] == 'Team Leader';

        if (aIsLeader && !bIsLeader) {
          return -1; 
        } else if (!aIsLeader && bIsLeader) {
          return 1;
        } else {
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
        }
      });

      setState(() {
        _teamMembers = members;
        _hasTeamLeader = members.any((member) => member['role'] == 'Team Leader');
      });
    } catch (e) {
      debugPrint('Error loading team members: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

 // Deletes a member locally and from Firebase (if it has an id).
  Future<void> _removeMember(int index) async {
    try {
      final member = _teamMembers[index];
      final memberId = member['id']?.toString();

      if (memberId != null && memberId.isNotEmpty) {
        setState(() => _isDeleting = true);
        await _databaseService.deleteTeamMember(widget.teamId, memberId);
        await _showCustomDialog(
          title: 'Success',
          message: 'Member removed successfully.',
          headerColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
      }

      await _loadTeamMembers(); 
    } catch (e) {
      debugPrint('Error deleting member from Firebase: $e');
      await _showCustomDialog(
        title: 'Error',
        message: 'Failed to remove member. Please try again.',
        headerColor: ilocateRed,
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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

  // Delete confirmation Dialog
  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
                Navigator.of(context).pop(); // Dismiss dialog
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
                Navigator.of(context).pop(); // Close dialog
                _removeMember(index); // Centralized deletion
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
      final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => x_teamMember(teamId: widget.teamId, hasTeamLeader: _hasTeamLeader),
      ),
    );
      if (result != null && result['success'] == true) {
      _loadTeamMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
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
    body: Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                              widget.teamName,
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

                  if (_isLoading)
                    Expanded(child: Center(child: CircularProgressIndicator(color: ilocateRed),))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _teamMembers.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _teamMembers.length) {
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
                            final member = _teamMembers[index];
                            final displayName = (member['fullname'] ?? member['name'] ?? '').toString();
                            final displayRole = (member['role'] ?? '').toString();

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MemberDetails(member: member),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
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
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          displayRole,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 8.0),
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

        // FULLSCREEN DELETE LOADER
        if (_isDeleting)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(color: ilocateRed),
            ),
          ),
      ],
    ),

    );
  }
}

// Member detail screen 
class MemberDetails extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetails({super.key, required this.member});

  // Age Calculator for Display
  String _calculateAge(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) return 'N/A';

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year == null || month == null || day == null) return 'N/A';

      final today = DateTime.now();
      final birthDate = DateTime(year, month, day);

      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return "$age";
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color ilocateRed = const Color(0xFFC70000);
    final fullname = member['fullname'] ?? member['name'] ?? 'N/A';
    final displayAge = _calculateAge(member['dateOfBirth'] ?? '');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90.0,
        title: const Text(
          'MEMBER DETAILS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        backgroundColor: ilocateRed,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(
                'Full Name',
                fullname,
                Icons.person,
                ilocateRed,
              ),
              _buildDetailCard(
                'ACDV ID',
                member['acdvId'] ?? 'N/A',
                Icons.badge,
                ilocateRed,
              ),
              _buildDetailCard(
                'Role',
                member['role'] ?? 'N/A',
                Icons.work,
                ilocateRed,
              ),
              _buildDetailCard(
                'Sex',
                member['sex'] ?? 'N/A',
                Icons.transgender,
                ilocateRed,
              ),
              _buildDetailCard(
                'Age',
                displayAge,
                Icons.calendar_today,
                ilocateRed,
              ),
              _buildDetailCard(
                'Address',
                member['address'] ?? 'N/A',
                Icons.location_on,
                ilocateRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}