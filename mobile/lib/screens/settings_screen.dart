import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../services/fcm_service.dart';

/// Displays Firebase Cloud Messaging (FCM) setup status, device token,
/// backend API configuration, and a local test alert trigger.
class SettingsScreen extends StatefulWidget {
  final ApiService apiService;
  final FcmService fcmService;

  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.fcmService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlController;
  bool? _apiHealthy;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.apiService.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() => _checking = true);
    widget.apiService.baseUrl = _urlController.text.trim();
    final ok = await widget.apiService.checkHealth();
    if (!mounted) return;
    setState(() {
      _apiHealthy = ok;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fcm = widget.fcmService;
    final fcmColor = switch (fcm.state) {
      FcmConnectionState.ready => Colors.green,
      FcmConnectionState.configMissing => Colors.orange,
      FcmConnectionState.permissionDenied => Colors.red,
      _ => Colors.grey,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: fcmColor),
                    const SizedBox(width: 10),
                    Text(
                      'Firebase Cloud Messaging (FCM)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Status: ${fcm.state.name}'),
                const SizedBox(height: 4),
                Text(
                  fcm.statusMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fcm.fcmToken ??
                            'Token unavailable (add google-services.json / GoogleService-Info.plist)',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (fcm.fcmToken != null)
                      IconButton(
                        tooltip: 'Copy FCM Token',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: fcm.fcmToken!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('FCM token copied.')),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await fcm.triggerSimulatedAlert();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated fire alert dispatched.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Trigger Local Test Alert'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backend FastAPI Connection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'http://10.0.2.2:8000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _checking ? null : _testConnection,
                      icon: const Icon(Icons.sync),
                      label: Text(_checking ? 'Checking...' : 'Test /health'),
                    ),
                    const SizedBox(width: 12),
                    if (_apiHealthy != null)
                      Text(
                        _apiHealthy! ? 'Connected' : 'Unreachable (Demo Mode)',
                        style: TextStyle(
                          color: _apiHealthy! ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
