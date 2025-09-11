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

  Alert({
    required this.rescueeName,
    required String incidentId,
    required this.deviceId,
    required this.date,
    required this.time,
    required this.location,
    required this.heartRate,
  }) : incidentId = _sanitizeIncidentId(incidentId);

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
    };
  }

  /// A static method to sanitize the incident ID by converting it to uppercase
  /// and removing all characters that are not letters or numbers.
  static String _sanitizeIncidentId(String input) {
    final sanitized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return sanitized;
  }
}
