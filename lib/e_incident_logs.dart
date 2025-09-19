import 'package:flutter/material.dart';
import 'c_mark_resolved.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/firebase_db.dart';
import 'models/alert.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  final Color ilocateRed = const Color(0xFFC70000);
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  final Set<String> _expandedLogs = {};
  final DatabaseService _db = DatabaseService();
  String? _rescuerTeamName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final teamsId = prefs.getString('teamsId');

    if (teamsId != null) {
      final teamData = await _db.getSingleTeam(teamsId);
      if (mounted && teamData != null) {
        setState(() {
          _rescuerTeamName = teamData['teamName'];
          _isLoading = false;
        });
      } else {
        if (mounted) _isLoading = false;
      }
    } else {
      if (mounted) _isLoading = false;
    }
  }

  void _toggleExpansion(String incidentId) {
    setState(() {
      if (_expandedLogs.contains(incidentId)) {
        _expandedLogs.remove(incidentId);
      } else {
        _expandedLogs.add(incidentId);
      }
    });
  }

  Future<void> _markResolved(String incidentId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _db.changeIncidentStatus(incidentId, 'resolved');

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showCustomDialog(
        title: 'Success',
        message: 'Incident $incidentId has been marked as resolved.',
        headerColor: Colors.green,
        icon: Icons.check_circle,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      _showCustomDialog(
        title: 'Error',
        message: 'Failed to mark incident as resolved.\nError: $e',
        headerColor: ilocateRed,
        icon: Icons.error,
        isSuccess: false,
      );
    }
  }

  // Reusable Show Dialog
  void _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
    bool isSuccess = false,
  }) {
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
                                if (isSuccess == true) {
                                  Navigator.of(context).pop();
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

  void _showMarkResolvedConfirmationDialog(
      BuildContext context, String incidentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(0),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(height: 4, color: ilocateRed),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: ilocateRed, size: 32),
                          const SizedBox(width: 8),
                          Text('STATUS UPDATE',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ilocateRed)),
                        ],
                      ),
                      const Divider(color: Colors.black26),
                      const SizedBox(height: 8),
                      const Text(
                        'Are you sure you want to mark this incident as resolved?',
                        style: TextStyle(fontSize: 14),
                      ),
                      Row(
                          children: const [
                            Icon(Icons.warning, color: Colors.red, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontStyle: FontStyle.italic,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: ilocateRed),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text('NO', style: TextStyle(color: ilocateRed)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _markResolved(incidentId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ilocateRed,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('YES', style: TextStyle(color: Colors.white)),
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
    );
  }

  String formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        title: const Text(
          'INCIDENT LOG',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
        ),
        backgroundColor: ilocateRed,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC70000)))
          : _rescuerTeamName == null
              ? const Center(child: Text('No team assigned.'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Search bar
                          TextField(
                            cursorColor: Colors.black87,
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'SEARCH INCIDENT ID',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFC70000), width: 2), // border color when focused
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Status filter
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: const [
                              DropdownMenuItem(value: 'ALL', child: Text('ALL')),
                              DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                              DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFC70000), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Logs list
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _db.streamRescuerLogs(_rescuerTeamName!),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) return const Center(child: Text('Failed to load logs.'));
                                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFC70000)));

                                final logsData = snapshot.data!
                                    .where((log) {
                                      final query = _searchController.text.toUpperCase();
                                      final incidentId = log['id'] ?? '';
                                      final status = log['status']?.toUpperCase() ?? '';
                                      final matchesSearch = incidentId.contains(query);
                                      final matchesStatus = _selectedStatus == 'ALL' || status == _selectedStatus.toUpperCase();
                                      return matchesSearch && matchesStatus;
                                    })
                                    .toList();

                                if (logsData.isEmpty) return const Center(child: Text('No logs available.'));

                                return ListView.builder(
                                  itemCount: logsData.length,
                                  itemBuilder: (context, index) {
                                    final log = logsData[index];
                                    final incidentId = log['id'] ?? '';
                                    final status = log['status'] ?? '';
                                    final isResolved = status.toLowerCase() == 'resolved';
                                    final isInProgress = status.toLowerCase() == 'in_progress';
                                    final isExpanded = _expandedLogs.contains(incidentId);
                                    final timestamp = log['lastTimestamp'] ?? log['firstTimestamp'];
                                    DateTime? dateTime;
                                    if (timestamp is int) {
                                      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
                                    } else if (timestamp is String) { 
                                      dateTime = DateTime.tryParse(timestamp);
                                    }
                                    final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
                                    final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';
                                    final location = log['value'] != null
                                        ? 'Lat ${log['value']['latitude'] ?? 'N/A'}, Long ${log['value']['longitude'] ?? 'N/A'}'
                                        : 'Lat N/A, Long N/A';
                                    final heartRate = log['value']?['heartRate']?.toString() ?? 'N/A';

                                    // Create an Alert object from the log data
                                    final alert = Alert.fromMap(log);

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _toggleExpansion(incidentId),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row( 
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded( 
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          'INCIDENT ID: $incidentId - ',
                                                          style: const TextStyle(fontWeight: FontWeight.bold,
                                                          fontSize: 12.0,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4), 
                                                      Text(
                                                        formatStatus(status),
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: isResolved ? Colors.green : Colors.blue,
                                                          fontSize: 12.0,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (isExpanded)
                                          Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey.shade400),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // DETAILS and RESCUEE NAME
                                                Row(
                                                  children: [
                                                    Text('DETAILS:',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: ilocateRed,
                                                            fontSize: 14)),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: FutureBuilder<Map<String, dynamic>?>(
                                                        future: _db.getDeviceInfoByDevuid(log['devuid']),
                                                        builder: (context, snapshot) {
                                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                                            return const Text('RESCUEE NAME: Loading...',
                                                            style: TextStyle(fontSize: 12.0), 
                                                            );
                                                          }
                                                          if (snapshot.hasError || !snapshot.hasData) {
                                                            return const Text('RESCUEE NAME: N/A',
                                                            style: TextStyle(fontSize: 12.0), 
                                                            );
                                                          }
                                                          final deviceInfo = snapshot.data!;
                                                          final rescueeName = deviceInfo['fullname'] ?? 'N/A';
                                                          return Text(
                                                            'RESCUEE NAME: $rescueeName',
                                                            style: const TextStyle(fontWeight: FontWeight.w500,
                                                            fontSize: 12.0
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // LOCATION and HEART RATE
                                                Wrap(
                                                  spacing: 20,
                                                  runSpacing: 8,
                                                  children: [
                                                    Text('LOCATION: $location', style: const TextStyle(fontSize: 12.0)),
                                                    Text('HEART RATE: $heartRate', style: const TextStyle(fontSize: 12.0)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // DATE and TIME
                                                Wrap(
                                                  spacing: 20,
                                                  children: [
                                                    Text('DATE: $date', style: const TextStyle(fontSize: 12.0)),
                                                    Text('TIME: $time', style: const TextStyle(fontSize: 12.0)),
                                                  ],
                                                ),
                                                if (isInProgress) ...[
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      OutlinedButton(
                                                        onPressed: () {
                                                          Navigator.pushReplacement(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => MarkResolved(
                                                                incidentId: log['id'] ?? '',
                                                                deviceId: alert.deviceId,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: ilocateRed,
                                                          side: BorderSide(color: ilocateRed),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                                          textStyle: const TextStyle(fontSize: 12),
                                                        ),
                                                        child: const Text('VIEW'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      OutlinedButton(
                                                        onPressed: () =>
                                                            _showMarkResolvedConfirmationDialog(context, incidentId),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: ilocateRed,
                                                          side: BorderSide(color: ilocateRed),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(20)),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                                                          textStyle: const TextStyle(fontSize: 12),
                                                        ),
                                                        child: const Text('MARK RESOLVED'),
                                                      ),
                                                    ],
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
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