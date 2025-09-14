import 'package:flutter/material.dart';
import 'models/alert.dart';
import 'g_admin_navigation.dart';
import 'w_alerts_confirm.dart';
import 'database/firebase_db.dart';

class wAlertsAssign extends StatefulWidget {
  final Alert alert;

  const wAlertsAssign({super.key, required this.alert});

  @override
  State<wAlertsAssign> createState() => _wAlertsAssignState();
}

class _wAlertsAssignState extends State<wAlertsAssign> {
  final Color ilocateRed = const Color(0xFFC70000);
  bool _isLoading = false;
  final DatabaseService _db = DatabaseService();
  String? _selectedGroup;

  // List of possible groups to assign the incident to
  List<String> _groupOptions = [];

  String? _fullName;
  String? _phone;
  String? _address;
  String? _dateOfBirth;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _fetchData(); 
  }

  Future<void> _fetchData() async {
  setState(() => _isLoading = true);
  // Use Future.wait to run both fetching methods at once
  await Future.wait([
    _fetchUserDetails(),
    _fetchTeams(),
  ]);
  setState(() => _isLoading = false);
}

  // Fetch team details
  Future<void> _fetchTeams() async {
  try {
    final teamNames = await _db.getTeamNames();
    setState(() {
      _groupOptions = teamNames;
    });
  } catch (e) {
    print('Error fetching team names: $e');
  }
}

  // Fetches user details from the database using the deviceId.
  Future<void> _fetchUserDetails() async {
    setState(() => _isLoading = true);
    try {
      final userDetails = await _db.getDeviceInfoByDevuid(widget.alert.deviceId);
      if (userDetails != null) {
        setState(() {
          _fullName = userDetails['fullname'];
          _phone = userDetails['phone'];
          _address = userDetails['address'];
          _dateOfBirth = userDetails['dateOfBirth'];
          _sex = userDetails['sex'];
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  // Function to handle the "Confirm" button click and navigate to w_alertsConfirm.dart
  void _onConfirm() {
    // Check if a group has been selected before navigating
    if (_selectedGroup != null) {
      debugPrint("Assigning incident to group: $_selectedGroup");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // The key change is here: we now pass the entire `Alert` object.
          builder: (context) => wAlertsConfirm(alert: widget.alert),
        ),
      );
    } else {
      // You could show a message to the user that they need to select a group
      // For now, we'll just print a debug message
      debugPrint("No group selected. Cannot confirm.");
    }
  }

  // Function to handle the back button tap, navigating to the main admin navigation screen
  void _onCancel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminNavigationScreen(selectedIndex: 1), // Navigate back to the main navigation screen and select the 'Alerts' tab (index 1)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          backgroundColor: ilocateRed,
          leadingWidth: 56,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          flexibleSpace: Align(
            alignment: Alignment.bottomLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.only(left: 96.0, bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ASSIGN INCIDENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26.0,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6.0),
                    Text(
                      'DETAILS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
        ),
      ),
      body: _isLoading // Added this conditional check
          ? Center(
              child: CircularProgressIndicator(color: ilocateRed),
            )
          : SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: ilocateRed, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: ilocateRed,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: ilocateRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        'RESCUEE NAME: ${alert.rescueeName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.black26, height: 24.0),
                              Text(
                                'PERSONAL DETAILS', // Changed from 'DETAILS'
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                  color: ilocateRed,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('FULL NAME', _fullName ?? 'N/A'), // Added this line
                                  _buildDetailRow('PHONE', _phone ?? 'N/A'), // Added this line
                                  _buildDetailRow('ADDRESS', _address ?? 'N/A'), // Added this line
                                  _buildDetailRow('AGE', _dateOfBirth != null ? _calculateAge(_dateOfBirth!) : 'N/A'), // Added this line with calculation
                                  _buildDetailRow('SEX', _sex ?? 'N/A'), // Added this line
                                  const SizedBox(height: 16.0),
                                  Text(
                                    'ALERT DETAILS', // Added new heading for clarity
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                      color: ilocateRed,
                                    ),
                                  ),
                                  const Divider(color: Colors.black26, height: 24.0), // Added a new divider
                                  _buildDetailRow('INCIDENT ID', alert.incidentId),
                                  _buildDetailRow('DATE', alert.date),
                                  _buildDetailRow('HEART RATE', alert.heartRate),
                                  _buildDetailRow('TIME', alert.time),
                                  _buildLocationRow('LOCATION', alert.location),
                                ],
                              ),
                              const SizedBox(height: 24.0),
                              // Dropdown menu for group assignment
                              DropdownButtonFormField<String>(
                                value: _selectedGroup,
                                decoration: InputDecoration(
                                  labelText: 'Assign to Group',
                                  labelStyle: TextStyle(color: ilocateRed),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(color: ilocateRed, width: 2.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: BorderSide(color: ilocateRed, width: 2.0),
                                  ),
                                ),
                                items: _groupOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedGroup = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 24.0),
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _onConfirm,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        backgroundColor: ilocateRed,
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                      ),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: _onCancel,
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(50),
                                        side: BorderSide(color: ilocateRed, width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30.0),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: ilocateRed,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(String label, String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0)),
          Flexible(
            child: Text(
              location,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }
}