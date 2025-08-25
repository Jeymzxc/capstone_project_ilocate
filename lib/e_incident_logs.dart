import 'package:flutter/material.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  final Color ilocateRed = const Color(0xFFC70000);
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';

  // State to track which incident IDs are expanded
  final Set<String> _expandedLogs = {};

  // Updated incident logs with example details for all entries
  final List<Map<String, String>> _incidentLogs = [
    {
      'incidentId': 'HASD26A',
      'status': 'RESOLVED',
      'rescueeName': 'Jane Smith',
      'date': 'May 09, 2025',
      'location': 'Lat 14.1234, Long 121.5678',
      'time': '10:00 AM',
      'heartRate': '85 BPM',
    },
    {
      'incidentId': 'BH2A36K',
      'status': 'RESOLVED',
      'rescueeName': 'John Doe',
      'date': 'May 10, 2025',
      'location': 'Lat 13.9563, Long 100.2018',
      'time': '4:30 AM',
      'heartRate': '120 BPM',
    },
    {
      'incidentId': 'XJ2A12K',
      'status': 'IN PROGRESS',
      'rescueeName': 'Emily White',
      'date': 'May 10, 2025',
      'location': 'Lat 14.0012, Long 121.1122',
      'time': '5:30 AM',
      'heartRate': '90 BPM',
    },
    {
      'incidentId': 'BJAA1CA',
      'status': 'IN PROGRESS',
      'rescueeName': 'Mike Brown',
      'date': 'May 11, 2025',
      'location': 'Lat 14.2345, Long 121.6789',
      'time': '1:15 PM',
      'heartRate': '110 BPM',
    },
  ];

  List<Map<String, String>> get _filteredLogs {
    final query = _searchController.text.toUpperCase();
    return _incidentLogs.where((log) {
      final matchesSearch = log['incidentId']!.contains(query);
      final matchesStatus = _selectedStatus == 'ALL' || log['status'] == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  void _markResolved(String incidentId) {
    setState(() {
      final index = _incidentLogs.indexWhere((log) => log['incidentId'] == incidentId);
      if (index != -1) {
        _incidentLogs[index]['status'] = 'RESOLVED';
      }
    });
  }

  // Toggles the expansion state of a specific log entry
  void _toggleExpansion(String incidentId) {
    setState(() {
      if (_expandedLogs.contains(incidentId)) {
        _expandedLogs.remove(incidentId);
      } else {
        _expandedLogs.add(incidentId);
      }
    });
  }

  // Shows the confirmation dialog before marking an incident as resolved
  void _showMarkResolvedConfirmationDialog(BuildContext context, String incidentId) {
    showDialog(
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
                  Container(
                    height: 4,
                    color: ilocateRed,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: ilocateRed,
                              size: 32,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'STATUS UPDATE',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: ilocateRed,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Are you sure you want to update the status of the incident?',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Changing the status cannot be undone. Once updated, it cannot revert back to the current status.',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Do you wish to continue?',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: ilocateRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text(
                                'NO',
                                style: TextStyle(color: ilocateRed),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                _markResolved(incidentId);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ilocateRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text(
                                'YES',
                                style: TextStyle(color: Colors.white),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90.0,
        title: const Text(
          'INCIDENT LOG',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: ilocateRed,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 🔍 Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'SEARCH INCIDENT ID',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // 🔽 Dropdown filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('ALL')),
                    DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                    DropdownMenuItem(value: 'IN PROGRESS', child: Text('IN PROGRESS')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(width: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // 📋 Incident logs
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final status = log['status'];
                      final incidentId = log['incidentId']!;
                      final isResolved = status == 'RESOLVED';
                      final isInProgress = status == 'IN PROGRESS';

                      // Check if the current log is expanded
                      final isExpanded = _expandedLogs.contains(incidentId);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🟥 Title Box - Now with a tap detector and an arrow icon
                          GestureDetector(
                            onTap: () => _toggleExpansion(incidentId),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'INCIDENT ID: $incidentId - ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        status!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isResolved ? Colors.green : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 📄 Details Box (only if isExpanded)
                          if (isExpanded) ...[
                            const SizedBox(height: 8.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // DETAILS and RESCUEE NAME on same line
                                  Row(
                                    children: [
                                      Text(
                                        'DETAILS:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: ilocateRed,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      const SizedBox(width: 16.0),
                                      Expanded(
                                        child: Text(
                                          'RESCUEE NAME: ${log['rescueeName']}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),

                                  // LOCATION and HEART RATE
                                  Wrap(
                                    spacing: 20.0,
                                    runSpacing: 8.0,
                                    children: [
                                      Text('LOCATION: ${log['location']}'),
                                      Text('HEART RATE: ${log['heartRate']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),

                                  // DATE and TIME
                                  Wrap(
                                    spacing: 20.0,
                                    children: [
                                      Text('DATE: ${log['date']}'),
                                      Text('TIME: ${log['time']}'),
                                    ],
                                  ),

                                  // Buttons for IN PROGRESS
                                  if (isInProgress) ...[
                                    const SizedBox(height: 12.0),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () {
                                            debugPrint("View $incidentId");
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: ilocateRed,
                                            side: BorderSide(color: ilocateRed),
                                          ),
                                          child: const Text('VIEW'),
                                        ),
                                        const SizedBox(width: 8.0),
                                        OutlinedButton(
                                          onPressed: () => _showMarkResolvedConfirmationDialog(context, incidentId),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: ilocateRed,
                                            side: BorderSide(color: ilocateRed),
                                          ),
                                          child: const Text('MARK RESOLVED'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24.0),
                        ],
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
