import 'package:firebase_database/firebase_database.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // Read TTN device data by DEVEUI
  Future<void> readTTNData(String deveui) async {
    DatabaseReference dbRef = _db.child("devices/$deveui");

    dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null) {
        print("Data for $deveui: $data");
      } else {
        print("No data found for $deveui");
      }
    });
  }


  // Admin login
  Future<bool> adminLogin(String username, String password) async {
    try {
      Query query = _db.child('admins').orderByChild('username').equalTo(username);
      DatabaseEvent event = await query.once();

      if (event.snapshot.value != null) {
        final admins = Map<String, dynamic>.from(event.snapshot.value as Map);
        final adminData = admins.values.first; // There should only be one result

        final storedPassword = adminData['password'];
        if (BCrypt.checkpw(password, storedPassword)) {
          print('Admin login successful');
          return true;
        } else {
          print('Password incorrect');
          return false;
        }
      }

      print('Admin not found');
      return false;
    } catch (e) {
      print('Firebase error: $e');
      return false;
    }
  }

  // Check for duplicate data 
  Future<Map<String, bool>> _checkDuplicates(Map<String, dynamic> adminData) async {
    Map<String, bool> duplicates = {
      'username': false,
      'email': false,
      'phone': false,
      'acdvId': false,
    };

    try {
      // Check for username duplicate
      Query usernameQuery = _db.child('admins').orderByChild('username').equalTo(adminData['username']);
      DatabaseEvent usernameEvent = await usernameQuery.once();
      if (usernameEvent.snapshot.value != null) {
        duplicates['username'] = true;
      }

      // Check for email duplicate
      Query emailQuery = _db.child('admins').orderByChild('email').equalTo(adminData['email']);
      DatabaseEvent emailEvent = await emailQuery.once();
      if (emailEvent.snapshot.value != null) {
        duplicates['email'] = true;
      }
      
      // Check for phone duplicate
      Query phoneQuery = _db.child('admins').orderByChild('phone').equalTo(adminData['phone']);
      DatabaseEvent phoneEvent = await phoneQuery.once();
      if (phoneEvent.snapshot.value != null) {
        duplicates['phone'] = true;
      }

      // Check for acdvId duplicate
      Query acdvIdQuery = _db.child('admins').orderByChild('acdvId').equalTo(adminData['acdvId']);
      DatabaseEvent acdvIdEvent = await acdvIdQuery.once();
      if (acdvIdEvent.snapshot.value != null) {
        duplicates['acdvId'] = true;
      }

      return duplicates;
    } catch (e) {
      print('Firebase error while checking for duplicates: $e');
      return duplicates; // Return an empty map for no duplicates on error
    }
  }

  // Register Admin
  Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> adminData) async {
    try {
      Map<String, bool> duplicates = await _checkDuplicates(adminData);
      if (duplicates.containsValue(true)) {
        return duplicates;
      }
      final hashedPassword = BCrypt.hashpw(adminData['password'], BCrypt.gensalt());
      adminData['password'] = hashedPassword;

      await _db.child('admins').push().set(adminData);

      print('Admin created successfully');
      return {'success': true}; // Indicate success with a map
    } catch (e) {
      print('Firebase error while creating admin: $e');
      return {'success': false}; // Indicate failure with a map
    }
  }
  
  // Display all Admins
  Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      DatabaseEvent event = await _db.child('admins').once();
      if (event.snapshot.value == null) {
        return [];
      }
      final Map<String, dynamic> adminsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      List<Map<String, dynamic>> adminsList = [];
      adminsMap.forEach((key, value) {
        final adminData = Map<String, dynamic>.from(value as Map);
        adminData['id'] = key; 
        adminsList.add(adminData);
      });
      return adminsList;
    } catch (e) {
      print('Firebase error fetching admins: $e');
      return [];
    }
  }

  // Function to delete an admin
  Future<void> deleteAdmin(String adminId) async {
    try {
      await _db.child('admins').child(adminId).remove();
      print('Admin with ID $adminId deleted successfully');
    } catch (e) {
      print('Firebase error deleting admin: $e');
    }
  }

  // Check for duplicate phone and devUid
  Future<Map<String, bool>> _checkDeviceDuplicates(Map<String, dynamic> deviceData) async {
    Map<String, bool> duplicates = {
      'phone': false,
      'devuid': false,
    };

    try {
      // List of fields to check
      final fieldsToCheck = ['phone', 'devuid'];

      for (String field in fieldsToCheck) {
        Query query = _db.child('devices').orderByChild(field).equalTo(deviceData[field]);
        DatabaseEvent event = await query.once();

        if (event.snapshot.value != null) {
          duplicates[field] = true;
        }
      }

      return duplicates;
    } catch (e) {
      print('Firebase error while checking for device duplicates: $e');
      return duplicates; 
    }
  }

  // Register Device
  Future<Map<String, dynamic>> createDevice(Map<String, dynamic> deviceData) async {
    try {
      // Check duplicates for phone & devUid
      final duplicates = await _checkDeviceDuplicates(deviceData);

      if (duplicates['devuid']! || duplicates['phone']!) {
        return {
          'success': false,
          'devuid': duplicates['devuid'],
          'phone': duplicates['phone'],
        };
      }

      // If no duplicates, save device
      await _db.child('devices').push().set(deviceData);
      print('Device created successfully');
      return {'success': true};
    } catch (e) {
      print('Firebase error while creating device: $e');
      return {'success': false};
    }
  }

  // Display all Devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    try {
      DatabaseEvent event = await _db.child('devices').once();
      if (event.snapshot.value == null) {
        return [];
      }
      final Map<String, dynamic> devicesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      
      List<Map<String, dynamic>> devicesList = [];
      devicesMap.forEach((key, value) {
        final deviceData = Map<String, dynamic>.from(value as Map);
        deviceData['id'] = key;
        devicesList.add(deviceData);
      });
      return devicesList;
    } catch (e) {
      print('Firebase error fetching devices: $e');
      return [];
    }
  }

  // Function to delete a device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _db.child('devices').child(deviceId).remove();
      print('Device with ID $deviceId deleted successfully');
    } catch (e) {
      print('Firebase error deleting device: $e');
    }
  }
}