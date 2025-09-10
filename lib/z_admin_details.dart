import 'package:flutter/material.dart';

class z_adminDetails extends StatelessWidget {
  final Map<String, dynamic> admin;

  const z_adminDetails({super.key, required this.admin});

  // Age Calculator for Display
  String _calculateAge(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) return 'N/A';

      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);

      if (year == null || month == null || day == null) return 'N/A';

      final today = DateTime.now();
      final birthDate = DateTime(year, month, day);

      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return "$age";
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color ilocateRed = const Color(0xFFC70000);
    final displayAge = _calculateAge(admin['dateOfBirth'] ?? '');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90.0,
        title: const Text(
          'ADMIN DETAILS',
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailCard(
                'Full Name',
                admin['fullname'] ?? 'N/A',
                Icons.person,
                ilocateRed,
              ),
              _buildDetailCard(
                'Username',
                admin['username'] ?? 'N/A',
                Icons.account_circle,
                ilocateRed,
              ),
              _buildDetailCard(
                'Address',
                admin['address'] ?? 'N/A',
                Icons.location_on,
                ilocateRed,
              ),
              _buildDetailCard(
                'Age',
                displayAge,
                Icons.calendar_today,
                ilocateRed,
              ),
              _buildDetailCard(
                'Sex',
                admin['sex'] ?? 'N/A',
                Icons.transgender,
                ilocateRed,
              ),
              _buildDetailCard(
                'ACDV ID',
                admin['acdvId'] ?? 'N/A',
                Icons.badge,
                ilocateRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}