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
                  const SizedBox(height: 16.0),
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

  @override
  bool get wantKeepAlive => true;

  void _toggleExpansion(String incidentId) {
    setState(() {
      if (_expandedLogs.contains(incidentId)) {
        _expandedLogs.remove(incidentId);
      } else {
        _expandedLogs.add(incidentId);
      }
    });
  }

  void _archiveLog(Map<String, dynamic> logToArchive) async {
    final incidentId = logToArchive['id']!;
    if ((logToArchive['status'] as String).toLowerCase() == 'resolved') {
      await widget.dbService.archiveIncident(incidentId);
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: widget.dbService.streamAllActiveIncidents(),
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
            onArchive: () => _archiveLog(log),
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

  @override
  bool get wantKeepAlive => true;

  void _toggleExpansion(String incidentId) {
    setState(() {
      if (_expandedLogs.contains(incidentId)) {
        _expandedLogs.remove(incidentId);
      } else {
        _expandedLogs.add(incidentId);
      }
    });
  }

  void _unarchiveLog(Map<String, dynamic> log) async {
    final incidentId = log['id']!;
    await widget.dbService.unarchiveIncident(incidentId);
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
      stream: widget.dbService.streamAllArchivedIncidents(),
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
                onArchive: () => _unarchiveLog(log),
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