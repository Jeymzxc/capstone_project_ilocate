import 'package:flutter/material.dart';
import 'z_settings.dart'; // Import the z_Settings.dart file

class SettingsPassword extends StatefulWidget {
  const SettingsPassword({super.key});

  @override
  State<SettingsPassword> createState() => _SettingsPasswordState();
}

class _SettingsPasswordState extends State<SettingsPassword> {
  // Define the custom red color used in the app
  final Color ilocateRed = const Color(0xFFC70000);

  // Controllers to manage the text in the input fields
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _verifyPasswordController = TextEditingController();

  // State variables for password visibility
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isVerifyPasswordVisible = false;

  // A GlobalKey to hold the state of the form, used for validation
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed to free up memory
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _verifyPasswordController.dispose();
    super.dispose();
  }

  // Function to show a custom dialog for success or error
  void _showAlertDialog(String title, String message, Color headerColor, {Widget? extraActions, Function? onOk}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  top: BorderSide(color: headerColor, width: 4),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(title == 'Success' ? Icons.check_circle_outline : Icons.error_outline, color: headerColor),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            color: headerColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      message,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 16),
                      child: extraActions ??
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                              if (onOk != null) {
                                onOk();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: headerColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30), // Increased radius
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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

  // This function will be called when the "Change Password" button is pressed
  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      // For temporary purposes, we'll check if the current password is "12345678"
      // In a real application, you would verify this against your backend.
      if (_currentPasswordController.text != '12345678') {
        _showAlertDialog(
          'Incorrect Current Password',
          'The current password you entered is wrong. Please try again.',
          ilocateRed,
          extraActions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _currentPasswordController.clear(); // Clear the field for retry
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ilocateRed, // Text color is red
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Increased radius
                    side: BorderSide(color: ilocateRed), // Red border
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        return; // Stop further execution
      }

      // If the form is valid and current password is correct, attempt to change the password.
      if (_newPasswordController.text == _verifyPasswordController.text) {
        _showAlertDialog(
          'Success',
          'Password successfully changed!',
          Colors.green,
          onOk: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const z_Settings()),
            );
          },
        );
        // Clear text fields after successful change
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _verifyPasswordController.clear();
      } else {
        _showAlertDialog(
          'Password Mismatch',
          'The passwords you entered don\'t match. Please retype both fields to continue.',
          ilocateRed,
        );
      }
    }
  }

  // This function is the validator for the new password text field
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password.';
    }
    if (value.length < 8) {
      return 'Must be at least 8 characters.';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Must include one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Must include one number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔐 Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 40),
              decoration: const BoxDecoration(
                color: Color(0xFFC70000), // ilocateRed constant
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const z_Settings()),
                      );
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'CHANGE PASSWORD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance the back button
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A container for the lock icon with a red circular background
                            Container(
                              height: 120,
                              width: 120,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC70000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 60.0,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            const Text(
                              'Please enter your current password and choose a new one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16.0),
                            ),
                            const SizedBox(height: 32.0),

                            // Current Password Textbox
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: !_isCurrentPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 15.0),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // New Password Textbox
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: !_isNewPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 15.0),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isNewPasswordVisible = !_isNewPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 8.0),

                            // Password requirements
                            // Use Padding to align the text with the text field's content
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Must be at least 8 characters',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                  Text(
                                    'Must include one uppercase letter & number',
                                    style: TextStyle(fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            // Verify Password Textbox
                            TextFormField(
                              controller: _verifyPasswordController,
                              obscureText: !_isVerifyPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Verify Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 15.0),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isVerifyPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isVerifyPasswordVisible = !_isVerifyPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please verify your new password.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32.0),

                            // Change Password button
                            ElevatedButton(
                              onPressed: _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC70000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Change Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // 🔙 Return Button at the bottom
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const z_Settings(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFC70000),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, -1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Return to Settings Page',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
