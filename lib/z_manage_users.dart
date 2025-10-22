import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'z_settings_add_admin.dart';
import 'z_register_device.dart';
import 'z_admin_details.dart';
import 'z_device_details.dart';
import 'a_user_login.dart';
import 'database/firebase_db.dart';

class z_settingsManageUsers extends StatefulWidget {
  const z_settingsManageUsers({super.key});

  @override
  _z_settingsManageUsersState createState() => _z_settingsManageUsersState();
}

class _z_settingsManageUsersState extends State<z_settingsManageUsers> {
  final Color ilocateRed = const Color(0xFFC70000);
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _admins = [];
  bool _isLoadingAdmins = true;

  List<Map<String, dynamic>> _devices = [];
  bool _isLoadingDevices = true;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _fetchDevices();
  }

  Future<void> _fetchAdmins() async {
    try {
      final List<Map<String, dynamic>> fetchedAdmins =
          await _dbService.getAdmins();
      setState(() {
        _admins = fetchedAdmins;
        _isLoadingAdmins = false;
      });
    } catch (e) {
      debugPrint('Error fetching admins: $e');
      setState(() {
        _isLoadingAdmins = false;
      });
    }
  }

  Future<void> _fetchDevices() async {
    try {
      final List<Map<String, dynamic>> fetchedDevices =
          await _dbService.getDevices();
      setState(() {
        _devices = fetchedDevices;
        _isLoadingDevices = false;
      });
    } catch (e) {
      debugPrint('Error fetching devices: $e');
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  // 🔹 Custom Dialog (consistent with your style)
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
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const UserLogin()),
                                    (route) => false,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
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

  Future<bool?> _showConfirmationDialog({
    required String itemType,
    required String itemName,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: ilocateRed,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.warning_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'Confirm Deletion',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            'Are you sure you want to remove this $itemType "$itemName"? This action cannot be undone.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ilocateRed, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'No',
                style: TextStyle(color: ilocateRed),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ilocateRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 90.0,
              title: const Text(
                'MANAGE ADMINS & DEVICES',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              backgroundColor: ilocateRed,
              centerTitle: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Color.fromARGB(179, 255, 255, 255),
                tabs: [
                  Tab(text: 'Admins'),
                  Tab(text: 'Devices'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Admin Management Tab
                _buildManagementTab(
                  title: 'Admins',
                  items: _admins,
                  onAdd: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const z_settingsAdd()),
                    );
                    if (result != null) _fetchAdmins();
                  },
                  onDelete: (index) async {
                    final shouldDelete = await _showConfirmationDialog(
                      itemType: 'Admin',
                      itemName: _admins[index]['username'] as String,
                    );

                    if (shouldDelete == true) {
                      setState(() => _isDeleting = true);

                      try {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final adminId = _admins[index]['id'] as String;

                        // Delete any admin account (super admin privilege)
                        await _dbService.deleteAdmin(adminId);
                        await _fetchAdmins();

                        setState(() => _isDeleting = false);

                        // If the deleted account is your own, log out and redirect
                        if (currentUser != null && currentUser.uid == adminId) {
                          await FirebaseAuth.instance.signOut();
                          _showCustomDialog(
                            title: 'Account Deleted',
                            message:
                                'Your admin account has been deleted. You will now be redirected to the login screen.',
                            headerColor: Colors.green,
                            icon: Icons.check_circle_outline,
                            isSuccess: true,
                          );
                        } else {
                          _showCustomDialog(
                            title: 'Admin Deleted',
                            message:
                                'The selected admin has been successfully deleted from the system.',
                            headerColor: Colors.green,
                            icon: Icons.check_circle_outline,
                          );
                        }
                      } catch (e) {
                        setState(() => _isDeleting = false);
                        _showCustomDialog(
                          title: 'Error',
                          message: 'An error occurred while deleting the admin:\n$e',
                          headerColor: Colors.red,
                          icon: Icons.error_outline,
                        );
                      }
                    }
                  },
                  isLoading: _isLoadingAdmins,
                  onTapItem: (index) {
                    final admin = _admins[index];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => z_adminDetails(admin: admin),
                      ),
                    );
                  },
                ),

                // Device Management Tab
                _buildManagementTab(
                  title: 'Devices',
                  items: _devices,
                  onAdd: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const z_settingsRegister()),
                    );
                    if (result != null) _fetchDevices();
                  },
                  onDelete: (index) async {
                    final shouldDelete = await _showConfirmationDialog(
                      itemType: 'Device',
                      itemName: _devices[index]['devuid'] as String,
                    );

                    if (shouldDelete == true) {
                      setState(() => _isDeleting = true);
                      final deviceId = _devices[index]['id'] as String;
                      await _dbService.deleteDevice(deviceId);
                      await _fetchDevices();
                      setState(() => _isDeleting = false);

                      _showCustomDialog(
                        title: 'Device Deleted',
                        message:
                            'Device has been successfully deleted from the system.',
                        headerColor: Colors.green,
                        icon: Icons.check_circle_outline,
                      );
                    }
                  },
                  isLoading: _isLoadingDevices,
                  onTapItem: (index) {
                    final device = _devices[index];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => z_deviceDetails(device: device),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        if (_isDeleting)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(color: ilocateRed),
            ),
          ),
      ],
    );
  }

  // 🔹 Reusable tab builder
  Widget _buildManagementTab({
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onAdd,
    required Function(int) onTapItem,
    required Function(int) onDelete,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              title == 'Devices' ? 'Add New Device' : 'Add New $title',
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ilocateRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
          ),
          const SizedBox(height: 24.0),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(color: ilocateRed),
                  )
                : items.isEmpty
                    ? Center(
                        child: Text(
                          'No $title found.',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final String displayKey =
                              title == 'Admins' ? 'username' : 'devuid';
                          final String displayTitle =
                              item[displayKey] as String? ?? 'N/A';

                          return Card(
                            elevation: 2,
                            margin:
                                const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                              title: Text(
                                displayTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () => onTapItem(index),
                              trailing: IconButton(
                                    icon: Icon(Icons.delete, color: ilocateRed),
                                    onPressed: () => onDelete(index),
                                  ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
