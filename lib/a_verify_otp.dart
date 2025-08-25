import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'a_new_password.dart';
import 'a_user_login.dart';
import 'a_forgot_password.dart';

class VerifyOTP extends StatefulWidget {
  final String phoneNumber;

  const VerifyOTP({super.key, required this.phoneNumber});

  @override
  State<VerifyOTP> createState() => _VerifyOTPState();
}

class _VerifyOTPState extends State<VerifyOTP> {
  // Define the consistent color for the theme at the class level
  final Color ilocateRed = const Color(0xFFC70000);

  // A list of 6 controllers and focus nodes for the OTP input fields
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _otpFocusNodes;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (index) => TextEditingController());
    _otpFocusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    // Dispose of all controllers and focus nodes to prevent memory leaks
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // A generic function to show a custom dialog for success or error
  void _showAlertDialog(
    String title,
    String message,
    Color headerColor,
    IconData icon,
    VoidCallback onOKPressed,
  ) {
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
                        onPressed: onOKPressed,
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

  // Helper function to build a single OTP input box with responsive sizing
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 45,
      height: 50,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1, // Only one digit per box
        style: const TextStyle(fontSize: 24),
        // Use FilteringTextInputFormatter to ensure only digits are entered
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          // Add content padding to vertically center the digit
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          counterText: "", // Hide the default character counter
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // A digit was entered, move focus to the next field if it exists
            if (index < _otpControllers.length - 1) {
              FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
            } else {
              // If it's the last field, unfocus and dismiss the keyboard
              FocusScope.of(context).unfocus();
              _verifyOtp();
            }
          } else if (index > 0) {
            // A digit was deleted (backspace), move focus to the previous field
            FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
          }
        },
      ),
    );
  }
  
  String getMaskedNumber(String number) {
    String formattedNumber = number;
    if (!formattedNumber.startsWith('+63')) {
      if (formattedNumber.startsWith('0')) {
        formattedNumber = formattedNumber.substring(1);
      }
      formattedNumber = '+63 $formattedNumber';
    }

    if (formattedNumber.length < 10) return formattedNumber;

    final prefix = formattedNumber.substring(0, formattedNumber.length - 5);
    final suffix = formattedNumber.substring(formattedNumber.length - 2);
    return '$prefix*** **$suffix';
  }

  void _verifyOtp() {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6 || otp != '123123') { // Example validation
      _showAlertDialog(
        'Invalid OTP',
        'The code you entered is incorrect or expired. Please check your messages and try again.',
        ilocateRed,
        Icons.lock_outline,
        () => Navigator.pop(context),
      );
    } else {
      _showAlertDialog(
        'Success',
        'OTP verified successfully! You can now set a new password.',
        Colors.green,
        Icons.check_circle_outline,
        () {
          Navigator.pop(context); // Close dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NewPassword()),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔴 Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 40),
              decoration: BoxDecoration(
                // Applied the new color here
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPassword()),
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

            // 📋 Form Section
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.sms_outlined, size: 96, color: ilocateRed),
                          const SizedBox(height: 12),
                          const Text(
                            'Verify OTP',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter the 6-digit code sent to your phone.',
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                getMaskedNumber(widget.phoneNumber),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPassword()),
                                  );
                                },
                                child: Text(
                                  'Change',
                                  style: TextStyle(
                                    // Applied the new color here
                                    color: ilocateRed, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) => _buildOtpBox(index)),
                          ),

                          const SizedBox(height: 24),

                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
                            child: ElevatedButton(
                              onPressed: _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                // Applied the new color here
                                backgroundColor: ilocateRed,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'CONFIRM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Didn't receive the code?"),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('OTP resent successfully.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    // Applied the new color here
                                    color: ilocateRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                  // Applied the new color here
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
