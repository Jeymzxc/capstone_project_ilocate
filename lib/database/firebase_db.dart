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
}