import 'package:flutter/material.dart';
import 'database/firebase_db.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'a_user_login.dart';

class SettingsPassword extends StatefulWidget {
  const SettingsPassword({super.key});

  @override
  State<SettingsPassword> createState() => _SettingsPasswordState();
}

class _SettingsPasswordState extends State<SettingsPassword> {
  final Color ilocateRed = const Color(0xFFC70000);

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _verifyPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isVerifyPasswordVisible = false;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; 

  final DatabaseService _databaseService = DatabaseService(); 

  @override
  void dispose() {
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

  void _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if new and verify passwords match
    if (_newPasswordController.text != _verifyPasswordController.text) {
      _showAlertDialog(
        'Password Mismatch',
        'The new passwords you entered don\'t match. Please retype both fields to continue.',
        ilocateRed,
      );
      return;
    }

        // Prevent using the same password as the current one
    if (_currentPasswordController.text == _newPasswordController.text) {
      _showAlertDialog(
        'Invalid Password',
        'The new password cannot be the same as the current password. Please choose a different one.',
        ilocateRed,
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the team ID from SharedPreferences (similar to admin)
      final prefs = await SharedPreferences.getInstance();
      final String? teamId = prefs.getString('teamsId');

      if (teamId == null) {
        _showAlertDialog(
          'Authentication Error',
          'Team ID not found. Please log in again.',
          ilocateRed,
        );
        return;
      }

      // Call your new function
      bool success = await _databaseService.changeTeamPassword(
        teamId,
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (success) {
        _showAlertDialog(
          'Success',
          'Password successfully changed! Please log in again.',
          Colors.green,
          onOk: () async {
            // Clear stored session
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();

            // Navigate to login screen and clear backstack
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const UserLogin()),
                (route) => false,
              );
            }
          },
        );

        // Clear text fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _verifyPasswordController.clear();
      } else {
        _showAlertDialog(
          'Failed to Change Password',
          'The current password you entered is incorrect. Please try again.',
          ilocateRed,
        );
      }
    } catch (e) {
      _showAlertDialog(
        'Error',
        'An error occurred: ${e.toString()}',
        ilocateRed,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      body: Stack(
        children: [
          // This is the main UI content, which will be layered at the bottom.
          SafeArea(
            child: Column(
              children: [
                // Header with back button and title
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
                          Navigator.pop(context);
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

                // Main scrollable content with form fields
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
                                // Lock icon container
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
                                  cursorColor: Colors.black87,
                                  controller: _currentPasswordController,
                                  obscureText: !_isCurrentPasswordVisible,
                                  maxLength: 20,
                                  decoration: InputDecoration(
                                    labelText: 'Current Password',
                                    counterText: '',
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFFC70000), 
                                    ), 
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: const BorderSide(color: Color(0xFFC70000), width: 2.0),
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
                                  cursorColor: Colors.black87,
                                  controller: _newPasswordController,
                                  obscureText: !_isNewPasswordVisible,
                                  maxLength: 20,
                                  decoration: InputDecoration(
                                    labelText: 'New Password',
                                    counterText: '',
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFFC70000), 
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: const BorderSide(color: Color(0xFFC70000), width: 2.0),
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
                                        'Must include one uppercase, lowercase, number, and a special character.',
                                        style: TextStyle(fontSize: 12.0),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),

                                // Verify Password Textbox
                                TextFormField(
                                  cursorColor: Colors.black87,
                                  controller: _verifyPasswordController,
                                  obscureText: !_isVerifyPasswordVisible,
                                  maxLength: 20,
                                  decoration: InputDecoration(
                                    labelText: 'Verify Password',
                                    counterText: '',
                                    floatingLabelStyle: const TextStyle(
                                      color: Color(0xFFC70000), 
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                     focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: const BorderSide(color: Color(0xFFC70000), width: 2.0),
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
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Return Button at the bottom
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
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

          // Conditional loading overlay: ModalBarrier and CircularProgressIndicator
          if (_isLoading)
            const Opacity(
              opacity: 0.7,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC70000)),
              ),
            ),
        ],
      ),
    );
  }
}
