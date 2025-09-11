import 'package:flutter/material.dart';
import 'c_alerts_respond.dart';
import 'models/alert.dart';
import 'c_confirm_respond.dart';

class IncidentRespond extends StatefulWidget {
  final Alert alert;

  const IncidentRespond({super.key, required this.alert});

  @override
  State<IncidentRespond> createState() => _IncidentRespondState();
}

class _IncidentRespondState extends State<IncidentRespond> {
  bool agreedToTerms = false;
  bool agreedToPrivacy = false;

  final Color ilocateRed = const Color(0xFFC70000);
  final Color linkBlue = Colors.blue;

  void _onConfirm() {
    debugPrint("Confirmed response for Incident ID: ${widget.alert.incidentId}");
    // Navigate to the confirmedRespond.dart screen after confirmation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ConfirmedRespond(
          incidentId: widget.alert.incidentId,
        ),
      ),
    );
  }

  void _showStatusUpdateDialog() {
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
                          'Are you sure you want to update the status of the incident ?',
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
                              onPressed: _onConfirm, // Call the confirmation function
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

  void _onConfirmClicked() {
    if (agreedToTerms && agreedToPrivacy) {
      _showStatusUpdateDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions of Use and Privacy Policy.'),
        ),
      );
    }
  }

  void _onCancel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AlertsRespond(alert: widget.alert),
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
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 32.0),
            child: GestureDetector(
              onTap: _onCancel,
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
            ),
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
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                          'DETAILS:',
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
                            _buildDetailRow('INCIDENT ID', alert.incidentId),
                            _buildDetailRow('DATE', alert.date),
                            _buildDetailRow('HEART RATE', alert.heartRate),
                            _buildDetailRow('TIME', alert.time),
                            _buildLocationRow('LOCATION', alert.location),
                          ],
                        ),
                        const SizedBox(height: 24.0),
                        GestureDetector(
                          onTap: () => setState(() => agreedToTerms = !agreedToTerms),
                          child: Row(
                            children: [
                              Checkbox(
                                value: agreedToTerms,
                                onChanged: (value) => setState(() => agreedToTerms = value ?? false),
                                shape: const CircleBorder(),
                                activeColor: ilocateRed,
                                checkColor: Colors.white,
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'I have read and agree to the '),
                                      TextSpan(
                                        text: 'Terms and Conditions of Use',
                                        style: TextStyle(color: linkBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => agreedToPrivacy = !agreedToPrivacy),
                          child: Row(
                            children: [
                              Checkbox(
                                value: agreedToPrivacy,
                                onChanged: (value) => setState(() => agreedToPrivacy = value ?? false),
                                shape: const CircleBorder(),
                                activeColor: ilocateRed,
                                checkColor: Colors.white,
                              ),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(color: Colors.black),
                                    children: [
                                      const TextSpan(text: 'I have read and agree to the '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(color: linkBlue),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _onConfirmClicked,
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
                      ], // <-- This closes the children list for the Column above
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
