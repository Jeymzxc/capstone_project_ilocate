import 'package:flutter/material.dart';
import 'package:ilocate/f_privacy_policy.dart';
import 'package:ilocate/f_terms_n_conditions.dart';
import 'c_alerts_respond.dart';
import 'models/alert.dart';
import 'c_confirm_respond.dart';
import 'database/firebase_db.dart';
import 'package:flutter/gestures.dart';

class IncidentRespond extends StatefulWidget {
  final Alert alert;
  final String deviceId;

  const IncidentRespond({
    super.key,
    required this.alert,
    required this.deviceId,
  });

  @override
  State<IncidentRespond> createState() => _IncidentRespondState();
}

class _IncidentRespondState extends State<IncidentRespond> {
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;

  final Color ilocateRed = const Color(0xFFC70000);
  final Color linkBlue = Colors.blue;
  final DatabaseService _db = DatabaseService();

  // User details
  String fullname = '';
  String phone = '';
  String address = '';
  String dateOfBirth = '';
  String sex = '';
  int? age;

  bool _isLoading = true;

  late TapGestureRecognizer _termsTap;
  late TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = _openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = _openPrivacy;
    _fetchUserDetails();
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

    void _openTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsAndConditions()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicy()),
    );
  }


  Future<void> _fetchUserDetails() async {
    try {
      final userDetails = await _db.getDeviceInfoByDevuid(widget.deviceId);

      if (mounted) {
        setState(() {
          if (userDetails != null) {
            fullname = userDetails['fullname'] ?? '';
            phone = userDetails['phone'] ?? '';
            address = userDetails['address'] ?? '';
            dateOfBirth = userDetails['dateOfBirth'] ?? '';
            sex = userDetails['sex'] ?? '';
            age = _calculateAge(dateOfBirth);
          }
          _isLoading = false; 
        });
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int? _calculateAge(String dob) {
    if (dob.isEmpty) return null;
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int years = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        years--;
      }
      return years;
    } catch (_) {
      return null;
    }
  }

    void _onConfirmClicked() {
    if (agreedToTerms && agreedToPrivacy) {
      _showStatusUpdateDialog(onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          // Update the incident status to 'in progress'
          await _db.changeIncidentStatus(widget.alert.incidentId, 'in_progress');

          if (!mounted) return;

          // Navigate to ConfirmedRespond page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmedRespond(alert: widget.alert),
            ),
          );
        } catch (e) {
          debugPrint("Error updating incident status: $e");
          _showCustomDialog(
            title: 'Error',
            message: 'Failed to update incident status.',
            headerColor: ilocateRed,
            icon: Icons.error_outline_rounded,
          );
        } finally {
          setState(() => _isLoading = false);
        }
      });
    } else {
      _showCustomDialog(
        title: "Notice",
        message: "Please agree to the Terms and Conditions of Use and Privacy Policy.",
        headerColor: ilocateRed,
        icon: Icons.error,
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


  void _showStatusUpdateDialog({required VoidCallback onConfirm}) {
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
                  Container(height: 4, color: ilocateRed),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note, color: ilocateRed, size: 32),
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
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: ilocateRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text('NO', style: TextStyle(color: ilocateRed)),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog first
                                onConfirm(); // Call the passed callback
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ilocateRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
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
        );
      },
    );
  }


  void _onCancel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsRespond(
          alert: widget.alert,
          deviceId: widget.deviceId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color:Color(0xFFC70000)),
        ),
      );
    }

    final alert = widget.alert;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: AppBar(
          backgroundColor: ilocateRed,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
            onPressed: _onCancel,
          ),
          flexibleSpace: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 96.0, bottom: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'INCIDENT RESPOND',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26.0,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    'CONFIRMATION',
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: ilocateRed, width: 2.0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rescuee Header
                  Container(
                    decoration: BoxDecoration(
                      color: ilocateRed,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white, size: 28),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'RESCUEE NAME: ${fullname.isNotEmpty ? fullname : alert.rescueeName}',
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

                  // Personal Details
                  Text("PERSONAL DETAILS:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: ilocateRed)),
                  const SizedBox(height: 8.0),
                  _buildDetailRow("PHONE", phone),
                  _buildDetailRow("ADDRESS", address),
                  _buildDetailRow("AGE", age?.toString() ?? "N/A"),
                  _buildDetailRow("SEX", sex),

                  const Divider(color: Colors.black26, height: 24.0),

                  // Incident Details
                  Text("INCIDENT DETAILS:",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                          color: ilocateRed)),
                  const SizedBox(height: 8.0),
                  _buildDetailRow('INCIDENT ID', alert.incidentId),
                  _buildDetailRow('DATE', alert.date),
                  _buildDetailRow('HEART RATE', alert.heartRate),
                  _buildDetailRow('TIME', alert.time),
                  _buildLocationRow('LOCATION', alert.location),

                  const SizedBox(height: 24.0),

                  // Terms & Buttons 
                  _termsSection(),
                  const SizedBox(height: 24.0),
                  _actionButtons(),
                ],
              ),
            ),
          ],
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
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
            softWrap: true,
            overflow: TextOverflow.ellipsis, 
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLocationRow(String label, String location) {
    return _buildDetailRow(label, location);
  }

  Widget _termsSection() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: agreedToTerms,
              onChanged: (v) => setState(() => agreedToTerms = v ?? false),
              shape: const CircleBorder(),
              activeColor: ilocateRed,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    ),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions of Use',
                      style: TextStyle(
                        color: linkBlue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _termsTap, 
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: agreedToPrivacy,
              onChanged: (v) => setState(() => agreedToPrivacy = v ?? false),
              shape: const CircleBorder(),
              activeColor: ilocateRed,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: linkBlue,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: _privacyTap, 
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  Widget _actionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onConfirmClicked,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: ilocateRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text("Confirm",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
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
            child: Text("Cancel",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: ilocateRed)),
          ),
        ),
      ],
    );
  }
}
