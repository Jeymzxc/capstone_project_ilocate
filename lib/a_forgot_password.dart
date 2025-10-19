import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'a_user_login.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Send Reset Email
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      // ✅ No existence check — secure modern approach
      await _auth.sendPasswordResetEmail(email: email);

      setState(() => _isLoading = false);

      // Success dialog (universal)
      _showCustomDialog(
        title: 'Check Your Email',
        message:
            'If an account exists for:\n\n$email\n\nYou’ll receive a password reset link shortly.\n'
            'Please check your Gmail inbox (and spam folder) to reset your password.',
        headerColor: Colors.green,
        icon: Icons.email_outlined,
        isSuccess: true,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String message = 'Failed to send reset email.';
      if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please wait a while before trying again.';
      }

      _showCustomDialog(
        title: 'Error',
        message: message,
        headerColor: Colors.red,
        icon: Icons.error_outline,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showCustomDialog(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
        headerColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }


  // Reusable Custom Dialog
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UserLogin(),
                                    ),
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

  InputDecoration buildRoundedInput(String label) {
    const textBoxBorder = Colors.grey;
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: textBoxBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const ilocateRed = Color(0xFFC70000);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 48, 8, 40),
                  decoration: const BoxDecoration(
                    color: ilocateRed,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 6),
                    ],
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 8),
                      Expanded(
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
                      SizedBox(width: 48),
                    ],
                  ),
                ),

                // Form Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined, size: 96, color: ilocateRed),
                                const SizedBox(height: 12),
                                const Text(
                                  "Forgot your password?",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Enter your registered email below and we'll send you a link to reset your password.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 24),

                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: Colors.black87, 
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    counterText: '',
                                    labelStyle: const TextStyle(color: Colors.black87), 
                                    floatingLabelStyle: const TextStyle(color: Color(0xFFC70000)), 
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                      borderSide: const BorderSide(color: Color(0xFFC70000), width: 2.0),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 32),

                                // Send Email button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _sendResetEmail,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ilocateRed,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: const Text(
                                      'Send Reset Link',
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
                ),

                // Return Button
                InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const UserLogin()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      color: ilocateRed,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, offset: Offset(0, -1), blurRadius: 5),
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

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
