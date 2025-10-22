import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:ilocate/models/hidden.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class DatabaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // --- INCIDENT MANAGEMENT FUNCTION ---


  // Streams incidents that are pending assignment (ADMIN dashboard only)
  Stream<List<Map<String, dynamic>>> streamPendingIncidents() {
    return _db.child('incidents')
        .orderByChild('status')
        .equalTo('pending')
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          incidentData['id'] = key;
          incidents.add(incidentData);
        });
      }
      return incidents;
    });
  }

  // Streams incidents that are active (For Admin Map Display)
  Stream<List<Map<String, dynamic>>> streamAdminIncidents() {
    return _db.child('incidents')
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          incidentData['id'] = key;

          // Only include incidents that are not cancelled or resolved
          final status = incidentData['status'] ?? '';
          if (status != 'cancelled' && status != 'resolved') {
            incidents.add(incidentData);
          }
        });
      }
      return incidents;
    });
  }


  // Streams incidents assigned to a specific team (Rescuer dashboard)
  Stream<List<Map<String, dynamic>>> streamRescuerIncidents(String teamId) {
    return _db.child('incidents')
        .orderByChild('assignedTeam')
        .equalTo(teamId)
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          // Only include incidents that are specifically 'assigned' and not yet in progress
          final status = incidentData['status'] as String?;
          if (status == 'assigned') {
            incidentData['id'] = key;
            incidents.add(incidentData);
          }
        });
      }
      return incidents;
    });
  }

  // Streams incidents that are active (For Rescuer Map Display)
  Stream<List<Map<String, dynamic>>> streamRescuerMapIncidents(String teamId) {
    return _db.child('incidents')
        .orderByChild('assignedTeam')
        .equalTo(teamId)
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          // Only include incidents that are specifically 'assigned' and 'in progress'
          final status = incidentData['status'] as String?;
          if (status == 'assigned' || status == 'in_progress') {
            incidentData['id'] = key;
            incidents.add(incidentData);
          }
        });
      }
      return incidents;
    });
  }

    // Get specific Team Name (Connected to Stream Rescuer Incidents)
    Future<Map<String, dynamic>?> getSingleTeam(String teamsId) async {
    try {
      // This fetches a single team document by its unique key/ID.
      DatabaseEvent event = await _db.child('teams').child(teamsId).once();
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        // Cast and return the single team's data.
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
    } catch (e) {
      debugPrint('Error fetching single team data: $e');
    }
    return null;
  }

  // Streams a single incident by its incidentId (real-time updates for Rescuer)
  Stream<Map<String, dynamic>?> streamIncidentById(String incidentId) {
    return _db.child('incidents/$incidentId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final incidentData = Map<String, dynamic>.from(data);
        incidentData['id'] = incidentId; // include the incidentId in the map
        return incidentData;
      }
      return null; // incident not found
    });
  }

    // Stream the latest alert for a specific device 
  Stream<Map<String, dynamic>?> streamLatestDeviceData(String deviceId) {
    final ref = _db.child("ttnData/$deviceId");
    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return null;
      final alertsMap = Map<String, dynamic>.from(data as Map);
      Map<String, dynamic>? latestAlert;
      int latestTimestamp = 0;

      alertsMap.forEach((alertId, alertData) {
        final alert = Map<String, dynamic>.from(alertData as Map);
        final timestamp = alert['timestamp'] is int
            ? alert['timestamp'] as int
            : int.tryParse(alert['timestamp'].toString()) ?? 0;

        if (timestamp > latestTimestamp) {
          latestTimestamp = timestamp;
          alert['id'] = alertId;
          alert['deviceId'] = deviceId;
          latestAlert = alert;
        }
      });

      return latestAlert;
    });
  }


  // Combined streamIncidentById and streamLatestDeviceData (for Rescuer)
  Stream<Map<String, dynamic>> streamCombinedIncident(String incidentId, String deviceId) {
    final incidentStream = streamIncidentById(incidentId);
    final ttnStream = streamLatestDeviceData(deviceId);

    Map<String, dynamic> latestIncident = {};
    Map<String, dynamic> latestTtn = {};

    // Create a controller to output the merged stream
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    void emitCombined() {
      final combinedValue = latestTtn.isNotEmpty
          ? latestTtn
          : Map<String, dynamic>.from(latestIncident['value'] ?? {});

      controller.add({
        ...latestIncident,
        'ttnData': latestTtn,
        'combinedValue': combinedValue,
      });
    }

    // Listen to both streams
    incidentStream.listen((incident) {
      latestIncident = incident ?? {};
      emitCombined();
    });

    ttnStream.listen((ttn) {
      latestTtn = ttn ?? {};
      emitCombined();
    });

    return controller.stream;
  }




  // Creates a new incident if none exists for the device, otherwise updates the existing incident
  Future<String?> createIncident(Map<String, dynamic> ttnData, String assignedTeam) async {
   
    final existingIncident = await getAnyIncidentByDevice(ttnData['device']);

    if (existingIncident != null) {
      final status = existingIncident['status'];
      final existingId = existingIncident['id'];

      if (status == 'pending' || status == 'in_progress' || status == 'assigned') {
        // It's still active, so just update it.
        await updateIncident(existingId, ttnData);
        return existingId;
      }

      if (status == 'cancelled' || status == 'resolved') {
        // It was previously cancelled or resolved.
        // Now, check if the new signal is actually new (based on timestamp).
        if (ttnData['timestamp'] > existingIncident['lastTimestamp']) {
          // If it's a new signal, reactivate the existing incident.
          await changeIncidentStatus(existingId, 'pending');
          await updateIncident(existingId, ttnData);
          debugPrint("Incident was $status. Re-opening as pending due to new distress signal.");
          return existingId;
        } else {

          debugPrint("Incident is $status — same TTN signal, skipping.");
          return null;
        }
      }
    }

    // If no incident exists at all, create a new one.
    final incidentRef = _db.child('incidents').push();
    await incidentRef.set({
      'deviceId': ttnData['device'],
      'devuid': ttnData['device'],
      'assignedTeam': assignedTeam,
      'status': 'pending',
      'value': ttnData['value'],
      'firstTimestamp': ttnData['timestamp'],
      'lastTimestamp': ttnData['timestamp'],
    });
    return incidentRef.key!;
  }


  // Updates an existing incident with latest TTN data (location, heart rate, timestamp)
  Future<void> updateIncident(String incidentId, Map<String, dynamic> ttnData) async {
    final incidentRef = _db.child('incidents/$incidentId');

    await incidentRef.update({
      'value': ttnData['value'],           // update distress, location, heartRate, etc.
      'lastTimestamp': ttnData['timestamp'], // latest timestamp from TTN
    });
  }


  // Changes the status of an incident
  Future<void> changeIncidentStatus(String incidentId, String newStatus, {String? assignedTeam}) async {
    final incidentRef = _db.child('incidents/$incidentId');
    final updates = <String, dynamic>{
      'status': newStatus,
    };

    if (newStatus == "assigned") {
      if (assignedTeam != null) {
        updates['assignedTeam'] = assignedTeam;
        updates['assignedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
    } else if (newStatus == "in_progress") {
      updates['startedAt'] = DateTime.now().millisecondsSinceEpoch;
    } else if (newStatus == "resolved") {
      updates['resolvedAt'] = DateTime.now().millisecondsSinceEpoch;
    } else if (newStatus == "cancelled") {
      updates['cancelledAt'] = DateTime.now().millisecondsSinceEpoch;
    }

    await incidentRef.update(updates);
  }


  // --- Check if an incident already exists for a device (any status) ---
  Future<Map<String, dynamic>?> getAnyIncidentByDevice(String deviceId) async {
    try {
      final query = await _db.child('incidents')
          .orderByChild('deviceId')
          .equalTo(deviceId)
          .get(); // Get all incidents for the device

      if (query.value != null) {
        final incidentsMap = Map<String, dynamic>.from(query.value as Map);
        Map<String, dynamic>? latestIncident;
        int latestTimestamp = 0;

        // Iterate to find the most recent incident, regardless of status
        incidentsMap.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value);
          final timestamp = incidentData['lastTimestamp'] ?? 0;
          if (timestamp > latestTimestamp) {
            latestTimestamp = timestamp;
            latestIncident = incidentData;
            latestIncident!['id'] = key;
          }
        });
        return latestIncident;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching any incident by device: $e");
      return null;
    }
  }

  // --- Check if an incident already exists for a device ---
  Future<Map<String, dynamic>?> getIncidentByDevice(String deviceId) async {
    try {
      final query = await _db.child('incidents')
          .orderByChild('deviceId')
          .equalTo(deviceId)
          .get();

      if (query.value != null) {
        final incidentsMap = Map<String, dynamic>.from(query.value as Map);

        for (var entry in incidentsMap.entries) {
          final incidentData = Map<String, dynamic>.from(entry.value);
          final status = incidentData['status'] as String?;

          // Only return incident if it is pending or in progress
          if (status == 'pending' || status == 'in_progress' || status == 'assigned') {  
            incidentData['id'] = entry.key;
            return incidentData;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint("Error fetching incident by device: $e");
      return null;
    }
  }









// --- DEVICE DATA MANAGEMENT FUNCTIONS ---

  // Function to stream real-time data for a specific device.
  Stream<Map<String, dynamic>?> streamDeviceData(String deveui) {
      DatabaseReference dbRef = _db.child("ttnData");
      
      return dbRef.orderByChild("device").equalTo(deveui).onValue.map((event) {
        final data = event.snapshot.value;
        if (data != null && data is Map<Object?, Object?>) {
          final deviceData = Map<String, dynamic>.from(data.values.first as Map);
          return deviceData;
        }
        return null;
      });
    }

  // Function to stream latest distress alerts (one per device)
  Stream<List<Map<String, dynamic>>> streamTtnDistressData() {
    return _db.child('ttnData').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map<String, dynamic> devicesMap = Map<String, dynamic>.from(data as Map);
      Map<String, Map<String, dynamic>> latestByDevice = {};

      devicesMap.forEach((deviceId, alerts) {
        final Map<String, dynamic> alertsMap = Map<String, dynamic>.from(alerts as Map);

        alertsMap.forEach((alertId, alertData) {
          final alert = Map<String, dynamic>.from(alertData as Map);

          if (alert['value']?['distress'] == true) {
            alert['id'] = alertId;
            alert['deviceId'] = deviceId;

            final int timestamp = (alert['timestamp'] is int)
                ? alert['timestamp']
                : int.tryParse(alert['timestamp'].toString()) ?? 0;

            if (!latestByDevice.containsKey(deviceId) ||
                timestamp > (latestByDevice[deviceId]?['timestamp'] ?? 0)) {
              latestByDevice[deviceId] = alert;
            }
          }
        });
      });

      return latestByDevice.values.toList();
    });
  }


  // Function to Fetch device info by devuid (e.g Personal Details of User.)
  Future<Map<String, dynamic>?> getDeviceInfoByDevuid(String devuid) async {
    try {
      final query = _db.child('devices').orderByChild('devuid').equalTo(devuid);
      final event = await query.once();
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final devicesMap = Map<String, dynamic>.from(snapshot.value as Map);
        final deviceId = devicesMap.keys.first;
        final deviceData = Map<String, dynamic>.from(devicesMap[deviceId] as Map);
        return deviceData;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching device info: $e");
      return null;
    }
  }






    // ---- LOGS INCIDENT FOR SPECIFIC RESCUE TEAMS ---

  Stream<List<Map<String, dynamic>>> streamRescuerLogs(String teamName) {
    return _db.child('incidents')
      .onValue
      .map((event) {
        List<Map<String, dynamic>> incidents = [];
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            final incidentData = Map<String, dynamic>.from(value as Map);
            final assignedTeam = incidentData['assignedTeam'] as String?;
            final status = incidentData['status'] as String?;
            
            // Include incidents assigned to this team and not cancelled
            if (assignedTeam == teamName && status != 'cancelled' && status != 'assigned') {
              incidentData['id'] = key;
              incidents.add(incidentData);
            }
          });
        }
        return incidents;
      });
  }



  // ---- LOGS INCIDENT FOR ADMIN ---

  // Streams all active incidents (used for the Admin's "Active Incidents" tab)
  Stream<List<Map<String, dynamic>>> streamAllActiveIncidents() {
    return _db.child('incidents')
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          final status = incidentData['status'] as String?;
          // Only include incidents with active statuses
          if (status != 'cancelled' && incidentData['archived'] != true) {
            incidentData['id'] = key;
            incidents.add(incidentData);
          }
        });
      }
      return incidents;
    });
  }

  // Streams all archived incidents
  Stream<List<Map<String, dynamic>>> streamAllArchivedIncidents() {
    return _db.child('incidents')
        .orderByChild('archived')
        .equalTo(true)
        .onValue
        .map((event) {
      List<Map<String, dynamic>> incidents = [];
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final incidentData = Map<String, dynamic>.from(value as Map);
          incidentData['id'] = key;
          incidents.add(incidentData);
        });
      }
      return incidents;
    });
  }

  // Function to update the `archived` status of an incident
  Future<void> archiveIncident(String incidentId) async {
    await _db.child('incidents/$incidentId').update({
      'archived': true,
    });
  }

  // Function to remove the `archived` status of an incident
  Future<void> unarchiveIncident(String incidentId) async {
    await _db.child('incidents/$incidentId').update({
      'archived': null, // Firebase removes the key if you set it to null
    });
  }





  // --- DUPLICATE MANAGEMENT FUNCTIONS ---

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
          debugPrint('Firebase error while checking for team duplicates: $e');
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
      debugPrint('Firebase error while checking for duplicates: $e');
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
      debugPrint('Firebase error while checking for device duplicates: $e');
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
      debugPrint('Firebase error while checking ACDV ID uniqueness: $e');
      return false; // Assume not unique on error
    }
  }





    // --- TEAM MANAGEMENT FUNCTION ---

  // Creates New Team using Firebase Auth
  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> teamData) async {
    try {
      // Check duplicates like before
      Map<String, dynamic> duplicates = await _checkTeamDuplicates(teamData);

      // Check for duplicate ACDV IDs among members
      List<String> duplicateAcdvIds = [];
      final membersData = teamData['members'] as Map<String, dynamic>;
      for (var memberData in membersData.values) {
        final isUnique = await _isAcdvIdUnique(memberData['acdvId']);
        if (!isUnique) {
          duplicateAcdvIds.add(memberData['acdvId']);
        }
      }

      if (duplicateAcdvIds.isNotEmpty) {
        duplicates['acdvId'] = duplicateAcdvIds;
      }

      if (duplicates.containsValue(true) || duplicateAcdvIds.isNotEmpty) {
        return {'success': false, 'duplicates': duplicates};
      }

      // Create Firebase Auth account for the team
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: teamData['email'],
        password: teamData['password'],
      );

      final uid = userCredential.user!.uid;

      // Remove plain password before saving to database
      teamData.remove('password');

      // Save team info in Realtime Database using the UID as key
      await _db.child('teams').child(uid).set(teamData);

      debugPrint('Team account created successfully');
      return {'success': true, 'uid': uid};
    } on FirebaseAuthException catch (e) {
      debugPrint('Auth error while creating team: ${e.message}');
      return {'success': false, 'error': e.message};
    } catch (e) {
      debugPrint('Firebase error while creating team: $e');
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
        debugPrint('Member added to team $teamId successfully');
        return {'success': true};
      } catch (e) {
        debugPrint('Firebase error adding team member: $e');
        return {'success': false};
      }
    }

  // Gets Specific Team Name only
  Future<List<String>> getTeamNames() async {
    try {
      DatabaseEvent event = await _db.child('teams').once();
      if (event.snapshot.value == null) {
        return [];
      }
      final Map<dynamic, dynamic> teamsMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      
      List<String> teamNames = [];
      teamsMap.forEach((key, value) {
        final teamData = Map<dynamic, dynamic>.from(value as Map);
        // Only extract the teamName
        teamNames.add(teamData['teamName'] as String);
      });
      return teamNames;
    } catch (e) {
      debugPrint('Firebase error fetching team names: $e');
      return [];
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
        debugPrint('Firebase error fetching teams: $e');
        return [];
      }
    }

  // Display Team Members
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
      debugPrint('Error fetching members: $e');
      return [];
    }
  }


  // Deletes a specific member from a team.
  Future<void> deleteTeamMember(String teamId, String memberId) async {
    try {
      // Navigate to the correct path 'teams/[teamId]/members/[memberId]' and remove the data.
      await _db.child('teams').child(teamId).child('members').child(memberId).remove();
      debugPrint('Member $memberId deleted from team $teamId successfully');
    } catch (e) {
      debugPrint('Firebase error deleting team member: $e');
    }
  }
    
  // Deletes entire team.
  Future<void> deleteTeam(String teamId) async {
    final url = Uri.parse('$baseUrl/delete-team');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': ADMIN_API_KEY,
    };
    final body = jsonEncode({'teamId': teamId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint('✅ Team deleted successfully from Cloud Function.');
    } else {
      debugPrint('❌ Failed to delete team: ${response.body}');
      throw Exception('Failed to delete team.');
    }
  }


  // Change Team Password (Firebase Auth version)
  Future<Map<String, dynamic>> changeTeamPassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in.'};
      }

      // 🔒 Step 1: Reauthenticate with the current (old) password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 🔑 Step 2: Update to the new password
      await user.updatePassword(newPassword);

      debugPrint('Password changed successfully for team: ${user.email}');
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password.';
      if (e.code == 'wrong-password') {
        message = 'The old password is incorrect.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again before changing your password.';
      }
      debugPrint('Auth error changing team password: ${e.message}');
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Unexpected error changing team password: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }




 // --- ADMIN MANAGEMENT FUNCTION ---

  
  // Change Admin Password (Firebase Auth version)
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in.'};
      }

      // 🔒 1️⃣ Re-authenticate the user first (required by Firebase)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 🔑 2️⃣ Update the password
      await user.updatePassword(newPassword);

      debugPrint('Password changed successfully for user: ${user.email}');
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password.';
      if (e.code == 'wrong-password') {
        message = 'The old password is incorrect.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Please log in again before changing your password.';
      }
      debugPrint('Auth error changing password: ${e.message}');
      return {'success': false, 'message': message};
    } catch (e) {
      debugPrint('Unexpected error changing password: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }


  // Register Admin using Firebase Auth 
  Future<Map<String, dynamic>> createAdmin(Map<String, dynamic> adminData) async {
    try {
      // Check for duplicate email or username
      Map<String, bool> duplicates = await _checkDuplicates(adminData);
      if (duplicates.containsValue(true)) {
        return {'success': false, 'duplicates': duplicates};
      }

      // Create a completely separate Firebase App instance for temporary use
      final FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'temporaryApp',
        options: Firebase.app().options,
      );

      // Use a FirebaseAuth instance linked to that temporary app
      final FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Create new admin account (does not affect current user session)
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: adminData['email'],
        password: adminData['password'],
      );

      final newUid = userCredential.user!.uid;

      // Remove password before saving to database
      adminData.remove('password');

      // Save admin details in Realtime Database
      await _db.child('admins').child(newUid).set({
        'id': newUid,
        ...adminData,
      });

      // Sign out and delete temporary app to prevent memory leaks
      await tempAuth.signOut();
      await tempApp.delete();

      debugPrint('✅ Admin account created successfully');
      return {'success': true, 'uid': newUid};
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth error while creating admin: ${e.message}');
      return {'success': false, 'error': e.message};
    } catch (e) {
      debugPrint('❌ Firebase error while creating admin: $e');
      return {'success': false, 'error': e.toString()};
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
      debugPrint('Firebase error fetching admins: $e');
      return [];
    }
  }

  // Delete own admin account (self-deletion only)
  Future<void> deleteAdmin(String adminId) async {
    final url = Uri.parse('$baseUrl/delete-admin');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': ADMIN_API_KEY,
    };
    final body = jsonEncode({'adminId': adminId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      debugPrint('✅ Admin deleted successfully from Cloud Function.');
    } else {
      debugPrint('❌ Failed to delete admin: ${response.body}');
      throw Exception('Failed to delete admin.');
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
      debugPrint('Device created successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('Firebase error while creating device: $e');
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
      debugPrint('Firebase error fetching devices: $e');
      return [];
    }
  }

  // Function to delete a device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _db.child('devices').child(deviceId).remove();
      debugPrint('Device with ID $deviceId deleted successfully');
    } catch (e) {
      debugPrint('Firebase error deleting device: $e');
    }
  }



   // --- LOGIN MANAGEMENT FUNCTION ---

  // Login for both Admins and Teams
  Future<Map<String, dynamic>> loginUser(String type, String email, String password) async {
    try {
      // Firebase Auth verifies credentials
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Fetch the user profile from Realtime Database using UID
      final snapshot = await _db.child('$type/$uid').get();

      if (!snapshot.exists) {
        return {
          'success': false,
          'message': 'Profile not found in database.',
        };
      }

      final userData = Map<String, dynamic>.from(snapshot.value as Map);

      // Save UID to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${type}Id', uid);

      // Build response
      final response = {
        'success': true,
        'id': uid,
        'username': userData['username'],
      };

      if (type == 'teams' && userData.containsKey('teamName')) {
        response['teamName'] = userData['teamName'];
      }

      return response;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed.';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      debugPrint('Error during $type login: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

}