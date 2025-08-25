// alert_details.dart
class Alert {
  final String rescueeName;
  final String incidentId;
  final String date;
  final String time;
  final String location;
  final String heartRate;

  Alert({
    required this.rescueeName,
    required String incidentId,
    required this.date,
    required this.time,
    required this.location,
    required this.heartRate,
  }) : incidentId = _sanitizeIncidentId(incidentId);

  static String _sanitizeIncidentId(String input) {
    final sanitized = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return sanitized;
  }
}
