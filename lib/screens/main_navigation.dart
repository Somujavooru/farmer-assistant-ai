import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import 'home/home_screen.dart';
import 'control/control_screen.dart';
import 'alerts/alerts_screen.dart';
import 'crop/crop_screen.dart';
import 'assistant/assistant_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final List<Widget> _screens = [
    const HomeScreen(),
    const ControlScreen(),
    const AlertsScreen(),
    const CropScreen(),
    const AssistantScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<NavigationProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: nav.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.currentIndex,
        onDestinationSelected: (index) {
          nav.setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_remote_outlined),
            selectedIcon: Icon(Icons.settings_remote),
            label: 'Control',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Crop',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
