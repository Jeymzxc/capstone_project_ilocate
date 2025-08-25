import 'package:flutter/material.dart';
import 'v_home.dart'; 
import 'w_alerts.dart'; 
import 'x_team.dart'; 
import 'y_logs.dart'; 
import 'z_settings.dart'; 

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin Settings Screen'));
  }
}

// Stateful widget to manage the state of the selected navigation item
class AdminNavigationScreen extends StatefulWidget {
  // Add a selectedIndex parameter to the constructor
  final int selectedIndex;

  const AdminNavigationScreen({super.key, this.selectedIndex = 0});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  // Define the custom red color used in the app
  final Color ilocateRed = const Color(0xFFC70000);

  // Variable to keep track of the currently selected index
  late int _selectedIndex;

  // List of widgets to display based on the selected index
  final List<Widget> _pages = [
    const AdminHomePage(),
    const wAlerts(),
    const x_Team(),
    const y_Logs(), // Updated to use the y_Logs page
    const z_Settings(), // Updated to use the z_Settings page
  ];

  @override
  void initState() {
    super.initState();
    // Use the value passed in the constructor to set the initial index
    _selectedIndex = widget.selectedIndex;
  }

  // Function to handle tapping on a navigation item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // A helper widget to build the selection indicator line below each icon.
  Widget _buildIndicator(bool isSelected) {
    return Container(
      height: 3.0,
      width: 45.0, // Match the width of the MainNavigationScreen
      margin: const EdgeInsets.only(top: 4.0), // Match the spacing
      color: isSelected ? Colors.white : Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: ilocateRed,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5), // Changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              // Use the same icons and sizing from the MainNavigationScreen
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home, size: 35.0),
                      _buildIndicator(_selectedIndex == 0),
                    ],
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, size: 35.0),
                      _buildIndicator(_selectedIndex == 1),
                    ],
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups, size: 35.0),
                      _buildIndicator(_selectedIndex == 2),
                    ],
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt, size: 35.0),
                      _buildIndicator(_selectedIndex == 3),
                    ],
                  ),
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune, size: 35.0),
                      _buildIndicator(_selectedIndex == 4),
                    ],
                  ),
                ),
                label: '',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.6),
            onTap: _onItemTapped,
            backgroundColor: ilocateRed,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
          ),
        ),
      ),
    );
  }
}
