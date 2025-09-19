import 'package:flutter/material.dart';
import 'a_user_login.dart';
import 'z_change_password.dart';
import 'z_terms_n_conditions.dart';
import 'z_privacy_policy.dart';
import 'z_manage_users.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'database/firebase_db.dart';

class z_Settings extends StatefulWidget {
  const z_Settings({super.key});

  @override
  _z_SettingsState createState() => _z_SettingsState();
}

class _z_SettingsState extends State<z_Settings> {
  final Color ilocateRed = const Color(0xFFC70000);

  String? _email;
  String? _phone;
  bool _isLoading = true;

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
  }

  Future<void> _loadAdminInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final adminId = prefs.getString('adminsId');

    if (adminId != null) {
      try {
        final admins = await _dbService.getAdmins();
        final admin = admins.firstWhere((a) => a['id'] == adminId, orElse: () => {});
        if (admin.isNotEmpty) {
          if (!mounted) return;   
          setState(() {
            _email = _maskEmail(admin['email'] ?? '');
            _phone = _maskPhone(admin['phone'] ?? '');
          });
        }
      } catch (e) {
        print('Error loading admin info: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _maskEmail(String email) {
    int atIndex = email.indexOf('@');
    if (atIndex <= 2) return email;
    return "${email.substring(0, 2)}****${email.substring(atIndex - 1)}";
  }

  String _maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return "${phone.substring(0, 4)}******${phone.substring(phone.length - 2)}";
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
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
                              Icons.logout,
                              color: ilocateRed,
                              size: 32,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded( 
                              child: Text(
                                'LOGOUT CONFIRMATION',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: ilocateRed,
                                ),
                                overflow: TextOverflow.ellipsis, 
                              ),
                            )
                          ],
                        ),
                        const Divider(color: Colors.black26),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
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
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserLogin()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
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

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: ilocateRed,
        ),
      ),
    );
  }

  Widget buildItem({
    required String label,
    required IconData icon,
    required BuildContext context,
    bool isItalic = false,
    bool isBold = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      splashColor: Colors.grey.withOpacity(0.2),
      highlightColor: Colors.grey.withOpacity(0.1),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16.0, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget buildItemWithValue({
    required String label,
    required String value,
    required IconData icon,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 90.0,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: ilocateRed,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                buildSectionTitle('Account Information'),
                buildItemWithValue(
                  label: 'Phone number',
                  value: _isLoading
                      ? 'Loading...'
                      : (_phone ?? 'Not set'),
                  icon: Icons.phone,
                  context: context,
                ),
                buildItemWithValue(
                  label: 'Email',
                  value: _isLoading
                      ? 'Loading...'
                      : (_email ?? 'Not set'),
                  icon: Icons.email,
                  context: context,
                ),
                buildItem(
                  label: 'Change Password',
                  icon: Icons.lock_reset,
                  isBold: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPassword()),
                    );
                  },
                  context: context,
                ),
                // Manage Admins and Users
                buildItem(
                  label: 'Manage Admins & Devices',
                  icon: Icons.group,
                  isBold: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const z_settingsManageUsers()),
                    );
                  },
                  context: context,
                ),

                const Divider(height: 32.0),

                buildSectionTitle('About'),
                buildItem(
                  label: 'Terms & Condition of Use',
                  icon: Icons.description,
                  isBold: true,
                  isItalic: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsAndConditions()),
                    );
                  },
                  context: context,
                ),
                buildItem(
                  label: 'Privacy Policy',
                  icon: Icons.privacy_tip,
                  isBold: true,
                  isItalic: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyPolicy()),
                    );
                  },
                  context: context,
                ),

                const Divider(height: 32.0),

                buildSectionTitle('Login'),
                buildItem(
                  label: 'Log out',
                  icon: Icons.logout,
                  isBold: true,
                  isItalic: true,
                  onTap: () {
                    _showLogoutConfirmationDialog(context);
                  },
                  context: context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}