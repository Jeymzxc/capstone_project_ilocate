import 'package:flutter/material.dart';
import 'b_home.dart';
import 'c_alerts.dart';
import 'd_team.dart';
import 'e_incident_logs.dart';
import 'f_settings.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Initialize the list of pages only once in initState.
    _widgetOptions = [
      const Home(),
      // Pass the selected index to Alerts for correct state handling.
      Alerts(selectedIndex: _selectedIndex),
      const Team(),
      const Logs(),
      // Correctly passes the callback to the Settings widget.
      Settings(onNavigateToTeam: () => _onItemTapped(2)),
    ];
  }

  // This function is called when a navigation bar item is tapped.
  // It updates the selected index and rebuilds the screen.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // A helper widget to build the selection indicator line below each icon.
  Widget _buildIndicator(bool isSelected) {
    return Container(
      height: 3.0,
      width: 45.0,
      margin: const EdgeInsets.only(top: 4.0),
      color: isSelected ? Colors.white : Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color ilocateRed = Color(0xFFC70000);

    return Scaffold(
      // The body displays the currently selected widget from the _widgetOptions list.
      // This is now safe because the list is only initialized once.
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: ilocateRed,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
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