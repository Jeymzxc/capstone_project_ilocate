import 'package:flutter/material.dart';
import 'a_login.dart';
import 'a_forgot_password.dart';
import 'g_rescuer_navigation.dart';
import 'g_admin_navigation.dart'; // Import the new admin navigation screen

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});

  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  // Define the custom red color used in the app
  final Color ilocateRed = const Color(0xFFC70000);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  // Temporary credentials for testing
  static const String _tempUsername = 'user';
  static const String _tempPassword = 'password123';
  static const String _tempAdminUsername = 'admin'; // Temporary admin username
  static const String _tempAdminPassword = 'adminpassword'; // Temporary admin password

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Color _getLabelColor(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      return ilocateRed; // Use the consistent red color
    }
    return Colors.grey;
  }

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
                        onPressed: () => Navigator.pop(context),
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

  void _handleLogin() {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showAlertDialog(
        'Missing Information',
        'Please enter both your email/username and password to log in.',
        ilocateRed,
        Icons.help_outline,
      );
    } else if (username == _tempUsername && password == _tempPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else if (username == _tempAdminUsername && password == _tempAdminPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminNavigationScreen()),
      );
    } else {
      _showAlertDialog(
        'Login Failed',
        'Incorrect email/password. Please check your credentials again.',
        ilocateRed,
        Icons.cancel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder roundedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.grey),
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/Logo1.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      Text(
                        'ILocate',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: ilocateRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('DISASTER',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: ilocateRed)),
                      const SizedBox(height: 2),
                      Text('RESPONDER APP',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: ilocateRed)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 👤 Username Field
                  TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(
                          color: _getLabelColor(_usernameFocus)),
                      prefixIcon: Icon(Icons.person, color: _getLabelColor(_usernameFocus)),
                      focusedBorder: roundedBorder.copyWith(
                        borderSide: BorderSide(color: ilocateRed, width: 2),
                      ),
                      enabledBorder: roundedBorder,
                    ),
                    onChanged: (_) => setState(() {}),
                    onTap: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // 🔒 Password Field
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                          color: _getLabelColor(_passwordFocus)),
                      prefixIcon: Icon(Icons.lock, color: _getLabelColor(_passwordFocus)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      focusedBorder: roundedBorder.copyWith(
                        borderSide: BorderSide(color: ilocateRed, width: 2),
                      ),
                      enabledBorder: roundedBorder,
                    ),
                    onChanged: (_) => setState(() {}),
                    onTap: () => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // 🔗 Forgot Password Navigation
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.blue), // Reverted to blue
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔴 Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ilocateRed,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📝 Create Account Prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAccount(),
                            ),
                          );
                        },
                        child: const Text(
                          'Create an account',
                          style: TextStyle(color: Colors.blue), // Reverted to blue
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
    );
  }
}
