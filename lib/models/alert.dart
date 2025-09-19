/// This class defines the structure for an alert object.
/// It also includes methods to serialize data to and from a database,
/// as well as logic to sanitize data upon creation.
class Alert {
  final String rescueeName;
  final String incidentId;
  final String deviceId;
  final String date;
  final String time;
  final String location;
  final String heartRate;
  final bool isAcknowledged;
  final String? assignedTeam;

  Alert({
    required this.rescueeName,
    required this. incidentId,
    required this.deviceId,
    required this.date,
    required this.time,
    required this.location,
    required this.heartRate,
    this.isAcknowledged = false,
    this.assignedTeam,
  });

  /// A factory constructor to create an Alert object from a generic Map (like from Realtime Database).
  factory Alert.fromMap(Map<dynamic, dynamic> map) {
    return Alert(
      rescueeName: map['rescueeName'] ?? '',
      incidentId: map['incidentId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      heartRate: map['heartRate'] ?? '',
      isAcknowledged: map['isAcknowledged'] ?? false,
      assignedTeam: map['assignedTeam'] as String?,
    );
  }

  /// A method to convert an Alert object into a Map for a database.
  Map<String, dynamic> toMap() {
    return {
      'rescueeName': rescueeName,
      'incidentId': incidentId,
      'deviceId': deviceId,
      'date': date,
      'time': time,
      'location': location,
      'heartRate': heartRate,
      'isAcknowledged': isAcknowledged,
      'assignedTeam': assignedTeam,
    };
  }

}
