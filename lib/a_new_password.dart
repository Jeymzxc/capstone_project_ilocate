// mag add na kapag cinonfirm yung password, yung nakalagay na text ay dapat appropriate like password must have an uppercase

import 'package:flutter/material.dart';
import 'a_user_login.dart';
import 'a_verify_otp.dart'; // Import VerifyOTP for back navigation

class NewPassword extends StatefulWidget {
  const NewPassword({super.key});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  // Define the consistent color for the theme at the class level
  final Color ilocateRed = const Color(0xFFC70000);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // State variables to control password visibility
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to build consistent rounded input decoration
  InputDecoration _buildRoundedInput(String label, bool isPasswordVisible, VoidCallback toggleVisibility) {
    const textBoxBorder = Colors.grey;
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: textBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey, // Set icon color to gray
        ),
        onPressed: toggleVisibility,
      ),
    );
  }

  // Function to show a custom dialog for success or error
  void _showAlertDialog(String title, String message, Color headerColor, IconData icon) {
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
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Icon(icon, color: headerColor),
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
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                          if (title == 'Success') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const UserLogin()),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
              decoration: BoxDecoration(
                // Applied the new color
                color: ilocateRed,
                boxShadow: const [
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
                      // Changed navigation to go back to VerifyOTP
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const VerifyOTP(phoneNumber: '')), // Pass an empty string or handle if phoneNumber is needed
                      );
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'FORGOT PASSWORD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Center( // Center the content
                  child: ConstrainedBox( // Constrain the max width of the content
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Applied the new color
                          Icon(Icons.lock_outline, size: 96, color: ilocateRed),
                          const SizedBox(height: 12),
                          const Text(
                            "Please enter your new password",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // New Password Input Field
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: !_isNewPasswordVisible, // Controlled by state
                            decoration: _buildRoundedInput(
                              'New Password',
                              _isNewPasswordVisible,
                              () {
                                setState(() {
                                  _isNewPasswordVisible = !_isNewPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'New password is required';
                              }
                              if (value.length < 8) {
                                return 'Must be at least 8 characters';
                              }
                              if (!value.contains(RegExp(r'[A-Z]'))) {
                                return 'Must include one uppercase letter';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return 'Must include one number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Must be at least 8 characters',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                Text(
                                  'Must include one uppercase letter & number',
                                  style: TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Confirm Password Input Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible, // Controlled by state
                            decoration: _buildRoundedInput(
                              'Confirm Password',
                              _isConfirmPasswordVisible,
                              () {
                                setState(() {
                                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm password is required';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _showAlertDialog(
                                    'Success',
                                    'Your password has been successfully updated. Please log in with your new credentials.',
                                    // Using green for the success dialog
                                    Colors.green,
                                    Icons.check_circle_outline,
                                  );
                                } else {
                                  // Updated error message for password mismatch
                                  _showAlertDialog(
                                    'Password Mismatch',
                                    'The passwords you entered don\'t match. Please retype both fields to continue.',
                                    // Using the red variable for the error dialog
                                    ilocateRed,
                                    Icons.error_outline,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                // Applied the new color
                                backgroundColor: ilocateRed,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
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

            // 🔙 Return Button at the bottom
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserLogin(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  // Applied the new color
                  color: ilocateRed,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, -1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Return to Login Page',
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
