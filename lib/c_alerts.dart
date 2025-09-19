import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database/firebase_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/alert.dart';
import 'c_alerts_view.dart';
import 'c_alerts_respond.dart';

class Alerts extends StatefulWidget {
  final int selectedIndex;

  const Alerts({super.key, required this.selectedIndex});

  @override
  State<Alerts> createState() => _AlertsState();
}

class _AlertsState extends State<Alerts> {
  final Color ilocateRed = const Color(0xFFC70000);
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isNavigating = false;

  void _onViewPressed(Alert alert) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsView(
          alert: alert, 
          deviceId: alert.deviceId
        ),
      ),
    ).then((_) {
      setState(() {
        _isNavigating = false;
      });
    });
  }

  void _onRespondPressed(Alert alert) {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsRespond(
          alert: alert,
          deviceId: alert.deviceId,
        ),
      ),
    ).then((_) {
      setState(() {
        _isNavigating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90.0,
        backgroundColor: ilocateRed,
        centerTitle: true,
        title: const Text(
          'SOS ALERTS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(10),
          ),
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Color(0xFFC70000))
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _rescuerTeamName == null
                      ? const Center(
                          child: Text('No team assigned.',
                              style: TextStyle(fontSize: 18.0)))
                      : StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _db.streamRescuerIncidents(_rescuerTeamName!),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Failed to load alerts.'));
                            }

                            final List<Map<String, dynamic>> alertsData =
                                snapshot.data ?? [];

                            if (alertsData.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No new alerts for your team.',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: alertsData.length,
                              itemBuilder: (context, index) {
                                final alertData = alertsData[index];
                                return _buildAlertCard(alertData, ilocateRed);
                              },
                            );
                          },
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> incident, Color ilocateRed) {
    final deviceId = incident['deviceId'] ?? '';
    final value = Map<String, dynamic>.from(incident['value'] ?? {});
    final heartRate = value['heartRate']?.toString() ?? 'N/A';
    final latitude = value['latitude']?.toString() ?? 'N/A';
    final longitude = value['longitude']?.toString() ?? 'N/A';

    final timestamp = incident['lastTimestamp'] ?? incident['firstTimestamp'];
    DateTime? dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp);
    }

    final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
    final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _db.getDeviceInfoByDevuid(deviceId),
      builder: (context, snapshot) {
        final deviceInfo = snapshot.data;
        final rescueeName = deviceInfo?['fullname'] ?? 'Unknown';

        final alertModel = Alert(
          rescueeName: rescueeName,
          incidentId: incident['id'] ?? incident['key'],
          date: date,
          time: time,
          location: 'Lat $latitude, Long $longitude',
          heartRate: '$heartRate BPM',
          deviceId: deviceId,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: ilocateRed, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DETAILS:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: ilocateRed,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESCUEE NAME: ${alertModel.rescueeName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'INCIDENT ID: ${alertModel.incidentId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'DATE: ${alertModel.date}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'TIME: ${alertModel.time}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LOCATION: ${alertModel.location}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'HEART RATE: ${alertModel.heartRate}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: _isNavigating ? null : () => _onViewPressed(alertModel),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC70000)),
                        foregroundColor: ilocateRed,
                      ),
                      child: const Text('VIEW'),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: _isNavigating ? null : () => _onRespondPressed(alertModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ilocateRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('RESPOND'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}