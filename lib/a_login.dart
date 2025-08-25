import 'package:flutter/material.dart';
import 'a_user_login.dart'; // If you're using direct push, make sure this is imported

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;

  @override
  Widget build(BuildContext context) {
    // Define the specific red color as requested
    const ilocateRed = Color(0xFFC70000);
    const textBoxBorder = Colors.grey;
    const iconColor = Colors.grey;

    InputDecoration buildRoundedInput(String label,
        {bool isPassword = false, bool isConfirm = false}) {
      bool isHidden = (isPassword && _obscurePassword) ||
          (isConfirm && _obscureConfirm);

      return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: textBoxBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: (isPassword || isConfirm)
            ? IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off : Icons.visibility,
                  color: iconColor,
                ),
                onPressed: () {
                  setState(() {
                    if (isPassword) _obscurePassword = !_obscurePassword;
                    if (isConfirm) _obscureConfirm = !_obscureConfirm;
                  });
                },
              )
            : null,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 🔴 Header with Drop Shadow
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 48, 8, 40),
              decoration: const BoxDecoration(
                color: ilocateRed, // Apply consistent red color
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Create Your Account',
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
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: buildRoundedInput('Enter E-mail'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}$')
                                    .hasMatch(value)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _usernameController,
                              decoration: buildRoundedInput('Username'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Username is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _contactController,
                              decoration: buildRoundedInput('Contact No.'),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Contact number is required';
                                }
                                if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                                  return 'Enter a valid contact number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration:
                                  buildRoundedInput('Password', isPassword: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Minimum 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscureConfirm,
                              decoration:
                                  buildRoundedInput('Repeat Password', isConfirm: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedTerms,
                                  activeColor: ilocateRed, // Apply consistent red color
                                  onChanged: (value) {
                                    setState(() => _agreedTerms = value ?? false);
                                  },
                                ),
                                Expanded( // Fix: Removed const
                                  child: Padding( // Fix: Removed const
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RichText(
                                      text: TextSpan(
                                        style:
                                            const TextStyle(color: Colors.black, fontSize: 14),
                                        children: [
                                          const TextSpan(text: 'I have read the '),
                                          const TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedPrivacy,
                                  activeColor: ilocateRed, // Apply consistent red color
                                  onChanged: (value) {
                                    setState(() => _agreedPrivacy = value ?? false);
                                  },
                                ),
                                Expanded( // Fix: Removed const
                                  child: Padding( // Fix: Removed const
                                    padding: const EdgeInsets.only(top: 12),
                                    child: RichText(
                                      text: TextSpan(
                                        style:
                                            const TextStyle(color: Colors.black, fontSize: 14),
                                        children: [
                                          const TextSpan(
                                              text:
                                                  'By confirming, you acknowledge that all personal data will be handled according to our '),
                                          const TextSpan(
                                            text: 'Privacy Policy',
                                            style: TextStyle(color: Colors.blue),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // 🔘 Continue Button with Navigation
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (!_agreedTerms || !_agreedPrivacy) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please accept Terms and Privacy Policy'),
                                          backgroundColor: ilocateRed, // Apply consistent red color
                                        ),
                                      );
                                      return;
                                    }

                                    // ✅ All validations passed – navigate to userLogin.dart
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const UserLogin(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ilocateRed, // Apply consistent red color
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Continue',
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
          ],
        ),
      ),
    );
  }
}
