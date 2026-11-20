import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/detection_event.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import 'alert_detail_screen.dart';

/// Main dashboard displaying real-time fire/smoke alerts, filter chips,
/// and chronological detection history.
class AlertsScreen extends StatefulWidget {
  final ApiService apiService;
  final FcmService fcmService;

  const AlertsScreen({
    super.key,
    required this.apiService,
    required this.fcmService,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _selectedFilter = 'all';
  bool _loading = true;
  List<DetectionEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    final events = await widget.apiService.fetchEvents(
      eventType: _selectedFilter == 'all' ? null : _selectedFilter,
    );
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unackedCount = _events.where((e) => !e.acknowledged).length;

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusSummaryCard(
                    unacknowledgedCount: unackedCount,
                    totalEvents: _events.length,
                    isDemoMode: widget.apiService.usingDemoData,
                    fcmReady:
                        widget.fcmService.state == FcmConnectionState.ready,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Event History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('all', 'All'),
                      _buildFilterChip('both', 'Fire & Smoke'),
                      _buildFilterChip('flame', 'Flame'),
                      _buildFilterChip('smoke', 'Smoke'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_events.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 56, color: Colors.green),
                    SizedBox(height: 12),
                    Text('No fire or smoke incidents recorded.'),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return _EventCard(
                    event: event,
                    onTap: () async {
                      final acknowledged = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AlertDetailScreen(
                            event: event,
                            apiService: widget.apiService,
                          ),
                        ),
                      );
                      if (acknowledged == true && mounted) {
                        setState(() {
                          _events[index] = event.copyWith(acknowledged: true);
                        });
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
        _loadEvents();
      },
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  final int unacknowledgedCount;
  final int totalEvents;
  final bool isDemoMode;
  final bool fcmReady;

  const _StatusSummaryCard({
    required this.unacknowledgedCount,
    required this.totalEvents,
    required this.isDemoMode,
    required this.fcmReady,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveAlerts = unacknowledgedCount > 0;
    final bannerColor =
        hasActiveAlerts ? Colors.deepOrange.shade800 : Colors.teal.shade700;

    return Card(
      color: bannerColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasActiveAlerts
                      ? Icons.local_fire_department
                      : Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasActiveAlerts
                        ? '$unacknowledgedCount Unacknowledged Alert(s)'
                        : 'All Monitored Zones Clear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniBadge(
                  icon: Icons.notifications_active_outlined,
                  label: fcmReady ? 'FCM Active' : 'FCM Preview Mode',
                ),
                _MiniBadge(
                  icon: Icons.cloud_outlined,
                  label: isDemoMode ? 'Demo Data' : 'API Connected',
                ),
                _MiniBadge(
                  icon: Icons.history,
                  label: '$totalEvents Total Events',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final DetectionEvent event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (event.eventType) {
      'both' => Colors.red.shade700,
      'flame' => Colors.deepOrange.shade600,
      _ => Colors.amber.shade800,
    };
    final icon = switch (event.eventType) {
      'both' => Icons.warning_amber_rounded,
      'flame' => Icons.local_fire_department,
      _ => Icons.cloud,
    };
    final title = switch (event.eventType) {
      'both' => 'FLAME & SMOKE',
      'flame' => 'FLAME DETECTED',
      _ => 'SMOKE DETECTED',
    };
    final timeStr = DateFormat('dd MMM · HH:mm:ss').format(event.detectedAt);
    final confidencePct = (event.maxConfidence * 100).toStringAsFixed(0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (event.acknowledged)
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.cameraName ?? 'Camera ${event.cameraId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$timeStr  •  $confidencePct% conf  •  ${event.frameStreak}-frame streak',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
