import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
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


  // --- Duplicate Management Functions ---

  // Checks for Duplicate Data across all Users (TEAMS SIDE)
  Future<Map<String, dynamic>> _checkTeamDuplicates(Map<String, dynamic> teamData) async {
    Map<String, dynamic> duplicates = {
      'username': false,
      'email': false,
      'phone': false,
      'acdvId': false,
    };

    try {
        final username = teamData['username'];
        final email = teamData['email'];
        final phone = teamData['phoneNo']; 

        // Check for username and email duplicates across admins and teams in parallel
        final results = await Future.wait([
          _db.child('admins').orderByChild('username').equalTo(username).once(),
          _db.child('teams').orderByChild('username').equalTo(username).once(),
          _db.child('admins').orderByChild('email').equalTo(email).once(),
          _db.child('teams').orderByChild('email').equalTo(email).once(),
          _db.child('admins').orderByChild('phone').equalTo(phone).once(),
          _db.child('teams').orderByChild('phoneNo').equalTo(phone).once(), 
          _db.child('devices').orderByChild('phone').equalTo(phone).once(),
        ]);

        // Check results for duplicates
          final usernameAdminEvent = results[0];
          final usernameTeamEvent = results[1];
          final emailAdminEvent = results[2];
          final emailTeamEvent = results[3];
          final phoneAdminEvent = results[4];
          final phoneTeamEvent = results[5];
          final phoneDeviceEvent = results[6];

          if (usernameAdminEvent.snapshot.value != null || usernameTeamEvent.snapshot.value != null) {
            duplicates['username'] = true;
          }
          if (emailAdminEvent.snapshot.value != null || emailTeamEvent.snapshot.value != null) {
            duplicates['email'] = true;
          }
          if (phoneAdminEvent.snapshot.value != null || phoneTeamEvent.snapshot.value != null || phoneDeviceEvent.snapshot.value != null) {
            duplicates['phone'] = true;
          }

          return duplicates;
        } catch (e) {
          print('Firebase error while checking for team duplicates: $e');
          return duplicates;
        }
      }

  // Checks for Duplicates Data Across all Users (ADMIN SIDE)
  Future<Map<String, bool>> _checkDuplicates(Map<String, dynamic> adminData) async {
    Map<String, bool> duplicates = {
      'username': false,
      'email': false,
      'phone': false,
      'acdvId': false,
    };

    try {
      final username = adminData['username'];
      final email = adminData['email'];
      final phone = adminData['phone'];
      final acdvId = adminData['acdvId'];

      // Use Future.wait to check all uniqueness constraints in parallel for efficiency
      final results = await Future.wait([
        _db.child('admins').orderByChild('username').equalTo(username).once(),
        _db.child('teams').orderByChild('username').equalTo(username).once(),
        _db.child('admins').orderByChild('email').equalTo(email).once(),
        _db.child('teams').orderByChild('email').equalTo(email).once(),
        _db.child('admins').orderByChild('phone').equalTo(phone).once(),
        _db.child('teams').orderByChild('phoneNo').equalTo(phone).once(),
        _db.child('devices').orderByChild('phone').equalTo(phone).once(),
        _isAcdvIdUnique(acdvId),
      ]);

      // Explicitly cast the first six results to DatabaseEvent
      final usernameAdminEvent = results[0] as DatabaseEvent;
      final usernameTeamEvent = results[1] as DatabaseEvent;
      final emailAdminEvent = results[2] as DatabaseEvent;
      final emailTeamEvent = results[3] as DatabaseEvent;
      final phoneAdminEvent = results[4] as DatabaseEvent;
      final phoneTeamEvent = results[5] as DatabaseEvent;
      final phoneDeviceEvent = results[6] as DatabaseEvent;
      final isAcdvIdUniqueResult = results[7] as bool;

      if (usernameAdminEvent.snapshot.value != null || usernameTeamEvent.snapshot.value != null) {
        duplicates['username'] = true;
      }
      if (emailAdminEvent.snapshot.value != null || emailTeamEvent.snapshot.value != null) {
        duplicates['email'] = true;
      }
      if (phoneAdminEvent.snapshot.value != null || phoneTeamEvent.snapshot.value != null || phoneDeviceEvent.snapshot.value != null) {
        duplicates['phone'] = true;
      }

      if (isAcdvIdUniqueResult == false) {
        duplicates['acdvId'] = true;
      }

      return duplicates;
    } catch (e) {
      print('Firebase error while checking for duplicates: $e');
      return duplicates;
    }
  }

    // Check for duplicate phone and devUid (DEVICES SIDE)
  Future<Map<String, bool>> _checkDeviceDuplicates(Map<String, dynamic> deviceData) async {
    Map<String, bool> duplicates = {
      'phone': false,
      'devuid': false,
    };

    try {
      final phone = deviceData['phone'];
      final devuid = deviceData['devuid'];

      final results = await Future.wait([
        _db.child('admins').orderByChild('phone').equalTo(phone).once(),
        _db.child('teams').orderByChild('phoneNo').equalTo(phone).once(),
        _db.child('devices').orderByChild('phone').equalTo(phone).once(),
        _db.child('devices').orderByChild('devuid').equalTo(devuid).once(),
      ]);

      if (results[0].snapshot.value != null || results[1].snapshot.value != null || results[2].snapshot.value != null) {
        duplicates['phone'] = true;
      }
      if (results[3].snapshot.value != null) {
        duplicates['devuid'] = true;
      }

      return duplicates;
    } catch (e) {
      print('Firebase error while checking for device duplicates: $e');
      return duplicates;
    }
  }

  // Check for a unique ACDV ID across both admins and rescuers.
  Future<bool> _isAcdvIdUnique(String acdvId) async {
    try {
      // Check 'admins' database for duplicate ACDV ID
      Query adminQuery = _db.child('admins').orderByChild('acdvId').equalTo(acdvId);
      DatabaseEvent adminEvent = await adminQuery.once();
      if (adminEvent.snapshot.value != null) {
        return false; // ACDV ID found in admins
      }

      // Check 'teams' database for members' ACDV ID
      DatabaseEvent teamsEvent = await _db.child('teams').once();
      if (teamsEvent.snapshot.value != null) {
        final teamsMap = Map<String, dynamic>.from(teamsEvent.snapshot.value as Map);
        for (var teamData in teamsMap.values) {
          if (teamData is Map && teamData.containsKey('members')) {
            final membersMap = Map<String, dynamic>.from(teamData['members'] as Map);
            for (var memberData in membersMap.values) {
              if (memberData is Map && memberData['acdvId'] == acdvId) {
                return false; // ACDV ID found in a team member
              }
            }
          }
        }
      }

      return true; // ACDV ID is unique
    } catch (e) {
      print('Firebase error while checking ACDV ID uniqueness: $e');
      return false; // Assume not unique on error
    }
  }





    // --- Team Management Functions ---

  // Creates New Team
  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> teamData) async {
    try {
      Map<String, dynamic> duplicates = await _checkTeamDuplicates(teamData);
      
      // Create a list to store all duplicate ACDV IDs found
      List<String> duplicateAcdvIds = [];

      final membersData = teamData['members'] as Map<String, dynamic>;
      for (var memberData in membersData.values) {
        final isUnique = await _isAcdvIdUnique(memberData['acdvId']);
        if (!isUnique) {
          duplicateAcdvIds.add(memberData['acdvId']);
        }
      }
      
      // Add the list of duplicate ACDV IDs to the duplicates map
      if (duplicateAcdvIds.isNotEmpty) {
        duplicates['acdvId'] = duplicateAcdvIds;
      }

      if (duplicates.containsValue(true) || duplicateAcdvIds.isNotEmpty) {
        return {'success': false, 'duplicates': duplicates};
      }

      // Hash the password before saving
      final hashedPassword = BCrypt.hashpw(teamData['password'], BCrypt.gensalt());
      teamData['password'] = hashedPassword;

      await _db.child('teams').push().set(teamData);
      print('Team created successfully');
      return {'success': true};
    } catch (e) {
      print('Firebase error while creating team: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

    // Adds a new member to a specific team.
    Future<Map<String, dynamic>> addTeamMember(String teamId, Map<String, dynamic> memberData) async {
      try {
        final isUnique = await _isAcdvIdUnique(memberData['acdvId']);
        if (!isUnique) {
          return {'success': false, 'message': 'ACDV ID already exists.'};
      }

        await _db.child('teams').child(teamId).child('members').push().set(memberData);
        print('Member added to team $teamId successfully');
        return {'success': true};
      } catch (e) {
        print('Firebase error adding team member: $e');
        return {'success': false};
      }
    }

    // Display Team Name
    Future<List<Map<String, dynamic>>> getTeams() async {
      try {
        DatabaseEvent event = await _db.child('teams').once();
        if (event.snapshot.value == null) {
          return [];
        }
        final Map<String, dynamic> teamsMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        List<Map<String, dynamic>> teamsList = [];
        teamsMap.forEach((key, value) {
          final teamData = Map<String, dynamic>.from(value as Map);
          teamData['id'] = key;
          teamsList.add(teamData);
        });
        return teamsList;
      } catch (e) {
        print('Firebase error fetching teams: $e');
        return [];
      }
    }

  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    try {
      DatabaseEvent event = await _db.child('teams/$teamId/members').once();
      if (event.snapshot.value == null) return [];

      final membersMap = Map<String, dynamic>.from(event.snapshot.value as Map);

      List<Map<String, dynamic>> membersList = [];
      membersMap.forEach((key, value) {
        final memberData = Map<String, dynamic>.from(value as Map);
        memberData['id'] = key;
        membersList.add(memberData);
      });

      return membersList; 
    } catch (e) {
      print('Error fetching members: $e');
      return [];
    }
  }


  // Deletes a specific member from a team.
  Future<void> deleteTeamMember(String teamId, String memberId) async {
    try {
      // Navigate to the correct path 'teams/[teamId]/members/[memberId]' and remove the data.
      await _db.child('teams').child(teamId).child('members').child(memberId).remove();
      print('Member $memberId deleted from team $teamId successfully');
    } catch (e) {
      print('Firebase error deleting team member: $e');
    }
  }
    
  // Deletes entire team.
  Future<void> deleteTeam(String teamId) async {
    try {
      await _db.child('teams').child(teamId).remove();
      print('Team with ID $teamId deleted successfully');
    } catch (e) {
      print('Firebase error deleting team: $e');
    }
  }







 // --- Admin Management Function ---

  // Change admin password
  Future<bool> changePassword(String adminId, String oldPassword, String newPassword) async {
    try {
      // Fetch the current admin data by their ID
      DatabaseEvent event = await _db.child('admins').child(adminId).once();

      if (event.snapshot.value == null) {
        print('Admin not found');
        return false;
      }

      final adminData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final storedPassword = adminData['password'];

      // Verify the old password
      if (!BCrypt.checkpw(oldPassword, storedPassword)) {
        print('Incorrect old password');
        return false;
      }

      // Hash the new password and update the database
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      await _db.child('admins').child(adminId).update({'password': hashedPassword});

      print('Password changed successfully for admin ID: $adminId');
      return true;
    } catch (e) {
      print('Firebase error changing password: $e');
      return false;
    }
  }

  // Admin login
  Future<bool> adminLogin(String username, String password) async {
    try {
      Query query = _db.child('admins').orderByChild('username').equalTo(username);
      DatabaseEvent event = await query.once();

      if (event.snapshot.value != null) {
        final admins = Map<String, dynamic>.from(event.snapshot.value as Map);
        final adminId = admins.keys.first;
        final adminData = admins.values.first; // There should only be one result

        final storedPassword = adminData['password'];
        if (BCrypt.checkpw(password, storedPassword)) {
          print('Admin login successful');

          // Store the admin ID locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('adminId', adminId);

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


  // Register Admin
  Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> adminData) async {
    try {
      Map<String, bool> duplicates = await _checkDuplicates(adminData);
      if (duplicates.containsValue(true)) {
        return {'success': false, 'duplicates': duplicates};
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