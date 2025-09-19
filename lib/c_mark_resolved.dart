import 'package:flutter/material.dart';
import 'package:ilocate/g_rescuer_navigation.dart';
import 'database/firebase_db.dart';
import 'package:intl/intl.dart';

class MarkResolved extends StatefulWidget {
  final String incidentId;
  final String deviceId;

  const MarkResolved({super.key, required this.incidentId, required this.deviceId});

  @override
  State<MarkResolved> createState() => _MarkResolvedState();
}

class _MarkResolvedState extends State<MarkResolved> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _db = DatabaseService();

  bool _isDetailsExpanded = true;
  bool _isLoading = true;

  // User details
  String? _fullName;
  String? _phone;
  String? _address;
  String? _dateOfBirth;
  String? _sex;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final userDetails = await _db.getDeviceInfoByDevuid(widget.deviceId);
      if (userDetails != null && mounted) {
        setState(() {
          _fullName = userDetails['fullname'];
          _phone = userDetails['phone'];
          _address = userDetails['address'];
          _dateOfBirth = userDetails['dateOfBirth'];
          _sex = userDetails['sex'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; 
        });
      }
    }
  }

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
    } catch (_) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
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
                                Navigator.of(context).pop(); // close the success dialog
                                if (isSuccess) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const MainNavigationScreen(initialIndex: 3)),
                                    (route) => false,
                                  );
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

void _showMarkResolvedConfirmationDialog(BuildContext context, String incidentId) {
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


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<Map<String, dynamic>?>(
          stream: _db.streamCombinedIncident(widget.incidentId, widget.deviceId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Scaffold(
                appBar: AppBar(
                  backgroundColor: ilocateRed,
                  title: const Text('LOCATION TRACKING'),
                ),
                body: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFC70000)),
                ),
              );
            }

            final incidentData = snapshot.data!;
            final incidentId = incidentData['id'] ?? widget.incidentId;
            final rescueeName = _fullName ?? incidentData['rescueeName'] ?? 'Unknown';

            final ttnData = incidentData['ttnData'] ?? {};
            final combinedValue = ttnData.isNotEmpty ? ttnData : Map<String, dynamic>.from(incidentData['value'] ?? {});

            final value = combinedValue.containsKey('value') ? Map<String, dynamic>.from(combinedValue['value'] ?? {}) : combinedValue;

            final heartRate = value['heartRate']?.toString() ?? 'N/A';
            final latitude = value['latitude']?.toString() ?? 'N/A';
            final longitude = value['longitude']?.toString() ?? 'N/A';
            final location = 'Lat $latitude, Long $longitude';

            final ttnTimestamp = ttnData['timestamp'];
            DateTime? dateTime;

            if (ttnTimestamp != null) {
              if (ttnTimestamp is int) {
                dateTime = DateTime.fromMillisecondsSinceEpoch(ttnTimestamp);
              } else if (ttnTimestamp is String) {
                dateTime = DateTime.tryParse(ttnTimestamp);
              }
            }

            if (dateTime == null) {
              final incidentTimestamp =
                  incidentData['lastTimestamp'] ?? incidentData['firstTimestamp'];
              if (incidentTimestamp is int) {
                dateTime = DateTime.fromMillisecondsSinceEpoch(incidentTimestamp);
              } else if (incidentTimestamp is String) {
                dateTime = DateTime.tryParse(incidentTimestamp);
              }
            }

            final date = dateTime != null ? DateFormat('MMM d, yyyy').format(dateTime) : 'N/A';
            final time = dateTime != null ? DateFormat('h:mm a').format(dateTime) : 'N/A';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: ilocateRed,
                toolbarHeight: 90.0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MainNavigationScreen(initialIndex: 3),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                title: const Text(
                  'LOCATION TRACKING',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22.0,
                  ),
                ),
                centerTitle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
              ),
              body: Stack(
                children: [
                  // Map placeholder
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'Map will be displayed here',
                          style: TextStyle(fontSize: 18.0, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  // Bottom Card with Details
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isDetailsExpanded = !_isDetailsExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'DETAILS',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: ilocateRed,
                                        ),
                                      ),
                                      Icon(
                                        _isDetailsExpanded
                                            ? Icons.keyboard_arrow_down
                                            : Icons.keyboard_arrow_up,
                                        color: ilocateRed,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12.0),
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    padding: _isDetailsExpanded
                                        ? const EdgeInsets.all(16.0)
                                        : EdgeInsets.zero,
                                    child: _isDetailsExpanded
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'PERSONAL DETAILS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                  color: ilocateRed,
                                                ),
                                              ),
                                              const Divider(
                                                color: Colors.grey,
                                                height: 16,
                                                thickness: 1,
                                              ),
                                              _buildDetailRow(
                                                  'Rescuee Name', rescueeName),
                                              _buildDetailRow(
                                                  'Phone', _phone ?? 'N/A'),
                                              _buildDetailRow(
                                                  'Address', _address ?? 'N/A'),
                                              _buildDetailRow(
                                                'Age',
                                                _dateOfBirth != null
                                                    ? _calculateAge(_dateOfBirth!)
                                                    : 'N/A',
                                              ),
                                              _buildDetailRow(
                                                  'Sex', _sex ?? 'N/A'),
                                              const SizedBox(height: 16.0),
                                              Text(
                                                'ALERT DETAILS',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                  color: ilocateRed,
                                                ),
                                              ),
                                              const Divider(
                                                color: Colors.grey,
                                                height: 16,
                                                thickness: 1,
                                              ),
                                              _buildDetailRow(
                                                  'Incident ID', incidentId),
                                              _buildDetailRow('Date', date),
                                              _buildDetailRow('Time', time),
                                              _buildDetailRow(
                                                  'Location', location),
                                              _buildDetailRow(
                                                  'Heart Rate', heartRate),
                                            ],
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showMarkResolvedConfirmationDialog(
                                  context, incidentId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ilocateRed,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text(
                                'MARK RESOLVED',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFC70000)),
              ),
            ),
          ),
      ],
    );
  }
}