import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class z_deviceDetails extends StatelessWidget {
  final Map<String, dynamic> device;

  const z_deviceDetails({super.key, required this.device});

    // Format Date into a readable format
    String _formatDate(String dateString) {
      if (dateString.isEmpty) {
        return 'N/A';
      }
      try {
        // Parse the date string "YYYY-MM-DD"
        final parts = dateString.split('-');
        if (parts.length != 3) {
          return dateString; 
        }

        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);

        if (year == null || month == null || day == null) {
          return dateString;
        }

        final dateTime = DateTime(year, month, day);
        return DateFormat('MMMM d, yyyy').format(dateTime);
      } catch (e) {
        return dateString; 
      }
    }

  @override
  Widget build(BuildContext context) {
    final Color ilocateRed = const Color(0xFFC70000);
    final formattedDateOfBirth = _formatDate(device['dateOfBirth'] ?? '');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90.0,
        title: const Text(
          'DEVICE DETAILS',
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
                'DEVUID',
                device['devuid'] ?? 'N/A',
                Icons.devices,
                ilocateRed,
              ),
              _buildDetailCard(
                'Full Name',
                device['fullname'] ?? 'N/A',
                Icons.person,
                ilocateRed,
              ),
              _buildDetailCard(
                'Phone',
                device['phone'] ?? 'N/A',
                Icons.phone,
                ilocateRed,
              ),
              _buildDetailCard(
                'Address',
                device['address'] ?? 'N/A',
                Icons.location_on,
                ilocateRed,
              ),
              _buildDetailCard(
                'Date of Birth',
                formattedDateOfBirth,
                Icons.cake,
                ilocateRed,
              ),
              _buildDetailCard(
                'Sex',
                device['sex'] ?? 'N/A',
                Icons.transgender,
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