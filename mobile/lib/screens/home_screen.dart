import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'alert_detail_screen.dart';
import 'alerts_screen.dart';
import 'cameras_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell for PyroGuard Mobile Client.
class HomeScreen extends StatefulWidget {
  final ApiService apiService;
  final FcmService fcmService;

  const HomeScreen({
    super.key,
    required this.apiService,
    required this.fcmService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  StreamSubscription<Map<String, dynamic>>? _tapSub;

  @override
  void initState() {
    super.initState();
    _tapSub = widget.fcmService.onAlertTapped.listen(_handleNotificationTap);
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final eventId = data['event_id'] as String?;
    if (eventId == null || !mounted) return;

    final event = await widget.apiService.fetchEventById(eventId);
    if (event == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlertDetailScreen(
          event: event,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AlertsScreen(
        apiService: widget.apiService,
        fcmService: widget.fcmService,
      ),
      CamerasScreen(apiService: widget.apiService),
      SettingsScreen(
        apiService: widget.apiService,
        fcmService: widget.fcmService,
      ),
    ];

    const titles = [
      'PyroGuard Alerts',
      'Monitored Cameras',
      'FCM & Settings',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_fire_department, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(titles[_selectedIndex]),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Cameras',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
