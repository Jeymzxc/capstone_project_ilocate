import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';

class y_Logs extends StatefulWidget {
  const y_Logs({super.key});

  @override
  State<y_Logs> createState() => _y_LogsState();
}

class _y_LogsState extends State<y_Logs> with AutomaticKeepAliveClientMixin {
  final Color ilocateRed = const Color(0xFFC70000);
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final Map<String, Map<String, dynamic>?> _deviceInfoCache = {};

  @override
  bool get wantKeepAlive => true;

  Future<Map<String, dynamic>?> getDeviceInfo(String devuid) async {
    if (_deviceInfoCache.containsKey(devuid)) {
      return _deviceInfoCache[devuid];
    } else {
      final info = await _dbService.getDeviceInfoByDevuid(devuid);
      _deviceInfoCache[devuid] = info;
      return info;
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(179, 255, 255, 255),
            tabs: [
              Tab(text: 'Active Incidents'),
              Tab(text: 'Archived Incidents'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                        borderSide: const BorderSide(color: Color(0xFFC70000), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ActiveTab(
                          dbService: _dbService,
                          searchController: _searchController,
                          getDeviceInfo: getDeviceInfo,
                        ),
                        ArchivedTab(
                          dbService: _dbService,
                          searchController: _searchController,
                          getDeviceInfo: getDeviceInfo,
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
}

/// ------------------- ACTIVE TAB -------------------
class ActiveTab extends StatefulWidget {
  final DatabaseService dbService;
  final TextEditingController searchController;
  final Future<Map<String, dynamic>?> Function(String) getDeviceInfo;

  const ActiveTab({
    super.key,
    required this.dbService,
    required this.searchController,
    required this.getDeviceInfo,
  });

  @override
  State<ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends State<ActiveTab>
    with AutomaticKeepAliveClientMixin {
  String _statusFilter = 'ALL';
  final Set<String> _expandedLogs = {};
  late final Stream<List<Map<String, dynamic>>> _activeIncidentsStream;

  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _activeIncidentsStream = widget.dbService.streamAllActiveIncidents();
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

  void _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: headerColor, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(message, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: headerColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('OK',
                                  style: TextStyle(color: Colors.white)),
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

  void _showArchiveConfirmationDialog(Map<String, dynamic> log) {
    final incidentId = log['id'] ?? 'N/A';

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
                  Container(height: 4, color: const Color(0xFFC70000)), // red header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.archive_rounded, color: Color(0xFFC70000), size: 32),
                            SizedBox(width: 8),
                            Text(
                              'CONFIRM ACTION',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC70000),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to archive Incident $incidentId?',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'This action cannot be undone.',
                              style: TextStyle(
                                fontSize: 13,
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
                                side: const BorderSide(color: Color(0xFFC70000)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'NO',
                                style: TextStyle(color: Color(0xFFC70000)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _archiveLog(log);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC70000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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

  Future<void> _archiveLog(Map<String, dynamic> logToArchive) async {
    final incidentId = logToArchive['id']!;
    if ((logToArchive['status'] as String).toLowerCase() == 'resolved') {
      try {
        await widget.dbService.archiveIncident(incidentId);
        _showCustomDialog(
          title: 'Success',
          message: 'Incident has been archived successfully.',
          headerColor: Colors.green,
          icon: Icons.check_circle_outline,
        );
      } catch (e) {
        _showCustomDialog(
          title: 'Error',
          message: 'Failed to archive. Please try again.',
          headerColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterLogs(List<Map<String, dynamic>> logs) {
    final query = widget.searchController.text.toUpperCase();

    return logs.where((log) {
      final status = (log['status'] as String?)?.toUpperCase() ?? '';
      final id = (log['id'] as String?)?.toUpperCase() ?? '';

      final matchesStatus =
          _statusFilter == 'ALL' || status == _statusFilter.toUpperCase();
      final matchesQuery = id.contains(query);

      return status != 'PENDING' && matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _statusFilter,
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text('ALL')),
            DropdownMenuItem(value: 'ASSIGNED', child: Text('ASSIGNED')),
            DropdownMenuItem(value: 'in_progress', child: Text('IN PROGRESS')),
            DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
          ],
          onChanged: (val) => setState(() => _statusFilter = val!),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0), 
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFC70000), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _activeIncidentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFC70000)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No active incidents found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)));
              }

              final logs = _filterLogs(snapshot.data!);

              return _buildLogList(logs, false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs, bool isArchived) {
    return ListView.builder(
      key: const PageStorageKey('activeList'),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final log = logs[i];
        final isExpanded = _expandedLogs.contains(log['id']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: LogCard(
            log: log,
            isExpanded: isExpanded,
            onToggle: () => _toggleExpansion(log['id']),
            onArchive: () => _showArchiveConfirmationDialog(log),
            isArchivedView: false,
            getDeviceInfo: widget.getDeviceInfo,
          ),
        );
      },
    );
  }
}

/// ------------------- ARCHIVED TAB -------------------
class ArchivedTab extends StatefulWidget {
  final DatabaseService dbService;
  final TextEditingController searchController;
  final Future<Map<String, dynamic>?> Function(String) getDeviceInfo;

  const ArchivedTab({
    super.key,
    required this.dbService,
    required this.searchController,
    required this.getDeviceInfo
  });

  @override
  State<ArchivedTab> createState() => _ArchivedTabState();
}

class _ArchivedTabState extends State<ArchivedTab>
    with AutomaticKeepAliveClientMixin {
  final Set<String> _expandedLogs = {};
  late final Stream<List<Map<String, dynamic>>> _archivedIncidentsStream;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    _archivedIncidentsStream = widget.dbService.streamAllArchivedIncidents();
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
  void _showCustomDialog({
    required String title,
    required String message,
    required Color headerColor,
    required IconData icon,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(icon, color: headerColor, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(message, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: headerColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('OK',
                                  style: TextStyle(color: Colors.white)),
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

  void _showUnarchiveConfirmationDialog(Map<String, dynamic> log) {
    final incidentId = log['id'] ?? 'N/A';

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
                  Container(height: 4, color: Colors.green),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.unarchive_rounded,
                                color: Colors.green, size: 32),
                            SizedBox(width: 8),
                            Text(
                              'CONFIRM ACTION',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to restore Incident $incidentId to Active?',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This will make the incident visible again in Active Logs.',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                'NO',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _unarchiveLog(log);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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

  void _unarchiveLog(Map<String, dynamic> log) async {
    final incidentId = log['id']!;
    try {
      await widget.dbService.unarchiveIncident(incidentId);
      _showCustomDialog(
        title: 'Success',
        message: 'Incident has been restored to Active.',
        headerColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      _showCustomDialog(
        title: 'Error',
        message: 'Failed to unarchive. Please try again.',
        headerColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  List<Map<String, dynamic>> _filterLogs(List<Map<String, dynamic>> logs) {
    final query = widget.searchController.text.toUpperCase();

    return logs.where((log) {
      final id = (log['id'] as String?)?.toUpperCase() ?? '';
      return id.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream:  _archivedIncidentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC70000)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('No archived incidents found.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)));
        }

        final logs = _filterLogs(snapshot.data!);

        return ListView.builder(
          key: const PageStorageKey('archivedList'),
          itemCount: logs.length,
          itemBuilder: (_, i) {
            final log = logs[i];
            final isExpanded = _expandedLogs.contains(log['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: LogCard(
                log: log,
                isExpanded: isExpanded,
                onToggle: () => _toggleExpansion(log['id']),
                onArchive: () => _showUnarchiveConfirmationDialog(log),
                isArchivedView: true,
                getDeviceInfo: widget.getDeviceInfo,
              ),
            );
          },
        );
      },
    );
  }
}

/// ------------------- REUSABLE LOG CARD -------------------
//
// REUSABLE LOG CARD
//
//
// REUSABLE LOG CARD
//
class LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onArchive;
  final bool isArchivedView;
  final Future<Map<String, dynamic>?> Function(String)? getDeviceInfo;

  const LogCard({
    super.key,
    required this.log,
    required this.isExpanded,
    required this.onToggle,
    required this.onArchive,
    required this.isArchivedView,
    this.getDeviceInfo,
  });

  String formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String status = (log['status'] as String?) ?? 'UNKNOWN';
    final assignedTeam = log['assignedTeam'] ?? 'N/A';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'assigned':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    final Map<String, dynamic> valueData =
        Map<String, dynamic>.from(log['value'] as Map? ?? {});

    String formatDate(int timestamp) =>
        DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

    String formatTime(int timestamp) =>
        DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(timestamp));

    final String date = log['firstTimestamp'] != null
        ? formatDate(log['firstTimestamp'])
        : 'N/A';
    final String time = log['firstTimestamp'] != null
        ? formatTime(log['firstTimestamp'])
        : 'N/A';
    final String heartRate =
        valueData['heartRate'] != null ? '${valueData['heartRate']} BPM' : 'N/A';
    final String location =
        (valueData['latitude'] != null && valueData['longitude'] != null)
            ? 'Lat ${valueData['latitude']}, Long ${valueData['longitude']}'
            : 'N/A';

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            // Header row
            Container(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'INCIDENT ID: ${log['id'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatStatus(status),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12.0,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    getDeviceInfo != null
                        ? FutureBuilder<Map<String, dynamic>?>(
                            future: getDeviceInfo!(log['devuid'] ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text(
                                  'RESCUEE NAME: Loading...',
                                  style: TextStyle(fontSize: 12.0), 
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text(
                                  'RESCUEE NAME: Error',
                                  style: TextStyle(fontSize: 12.0), 
                                );
                              }
                              final deviceInfo = snapshot.data;
                              final rescueeName = deviceInfo != null ? deviceInfo['fullname'] ?? 'N/A' : 'N/A';
                              return Text(
                                'RESCUEE NAME: $rescueeName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.0, 
                                ),
                              );
                            },
                          )
                        : const Text(
                            'RESCUEE NAME: N/A',
                            style: TextStyle(fontSize: 12.0), 
                          ),
                    const SizedBox(height: 8),
                    Text(
                      'ASSIGNED TEAM: $assignedTeam',
                      style: const TextStyle(fontSize: 12.0), 
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      children: [
                        Text(
                          'LOCATION: $location',
                          style: const TextStyle(fontSize: 12.0), 
                        ),
                        Text(
                          'HEART RATE: $heartRate',
                          style: const TextStyle(fontSize: 12.0), 
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      children: [
                        Text(
                          'DATE: $date',
                          style: const TextStyle(fontSize: 12.0), 
                        ),
                        Text(
                          'TIME: $time',
                          style: const TextStyle(fontSize: 12.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 120,
                        child: isArchivedView
                            ? ElevatedButton(
                                onPressed: onArchive,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
                                ),
                                child: const Text(
                                  'UNARCHIVE',
                                  style: TextStyle(fontSize: 12.0), 
                                ),
                              )
                            : OutlinedButton(
                                onPressed: status.toLowerCase() == 'resolved' ? onArchive : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: status.toLowerCase() == 'resolved' ? Colors.red : Colors.grey,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), 
                                ),
                                child: const Text(
                                  'ARCHIVE',
                                  style: TextStyle(fontSize: 12.0), 
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}