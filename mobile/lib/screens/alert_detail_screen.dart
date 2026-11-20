import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/detection_event.dart';
import '../services/api_service.dart';

/// Detailed view of a confirmed fire/smoke incident, including a snapshot
/// viewer with YOLO bounding-box overlays and alert acknowledgement.
class AlertDetailScreen extends StatefulWidget {
  final DetectionEvent event;
  final ApiService apiService;

  const AlertDetailScreen({
    super.key,
    required this.event,
    required this.apiService,
  });

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  late bool _acknowledged;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _acknowledged = widget.event.acknowledged;
  }

  Future<void> _acknowledge() async {
    setState(() => _submitting = true);
    await widget.apiService.acknowledgeEvent(widget.event.id);
    if (!mounted) return;
    setState(() {
      _acknowledged = true;
      _submitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident marked as acknowledged.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final formattedTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(event.detectedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_acknowledged),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AnnotatedSnapshotPreview(event: event),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.cameraName ?? 'Camera ${event.cameraId}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (event.cameraLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.cameraLocation!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const Divider(height: 24),
                  _InfoRow(label: 'Event ID', value: event.id),
                  _InfoRow(
                    label: 'Event Type',
                    value: event.eventType.toUpperCase(),
                  ),
                  _InfoRow(
                    label: 'Max Confidence',
                    value: '${(event.maxConfidence * 100).toStringAsFixed(1)}%',
                  ),
                  _InfoRow(
                    label: 'Temporal Streak',
                    value: '${event.frameStreak} consecutive positive frames',
                  ),
                  _InfoRow(label: 'Detected At', value: formattedTime),
                  _InfoRow(
                    label: 'Status',
                    value: _acknowledged ? 'Acknowledged' : 'Active / Pending',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detected Bounding Boxes (${event.boxes.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...event.boxes.map(
            (box) => Card(
              child: ListTile(
                leading: Icon(
                  box.isFlame ? Icons.local_fire_department : Icons.cloud,
                  color: box.isFlame ? Colors.deepOrange : Colors.amber.shade800,
                ),
                title: Text(
                  '${box.className.toUpperCase()} · ${(box.confidence * 100).toStringAsFixed(1)}%',
                ),
                subtitle: Text(
                  'Box: (${box.xMin.toStringAsFixed(2)}, ${box.yMin.toStringAsFixed(2)}) '
                  '→ (${box.xMax.toStringAsFixed(2)}, ${box.yMax.toStringAsFixed(2)})',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: (_acknowledged || _submitting) ? null : _acknowledge,
            icon: Icon(_acknowledged ? Icons.check_circle : Icons.done_all),
            label: Text(
              _acknowledged
                  ? 'Alert Acknowledged'
                  : (_submitting ? 'Updating...' : 'Acknowledge Alert'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnotatedSnapshotPreview extends StatelessWidget {
  final DetectionEvent event;

  const _AnnotatedSnapshotPreview({required this.event});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (event.snapshotPath != null &&
                event.snapshotPath!.startsWith('http'))
              Image.network(
                event.snapshotPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderFrame(),
              )
            else
              _placeholderFrame(),
            CustomPaint(
              painter: _BoundingBoxPainter(boxes: event.boxes),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.snapshotPath ?? 'RTSP Snapshot Preview (Bounding Boxes)',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderFrame() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F242D), Color(0xFF2E3440)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.videocam_outlined, size: 48, color: Colors.white24),
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<DetectionBox> boxes;

  _BoundingBoxPainter({required this.boxes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final box in boxes) {
      // Support normalized [0, 1] coordinates (or scale pixel coordinates safely).
      final isNormalized = box.xMax <= 1.0 && box.yMax <= 1.0;
      final left = isNormalized ? box.xMin * size.width : box.xMin;
      final top = isNormalized ? box.yMin * size.height : box.yMin;
      final right = isNormalized ? box.xMax * size.width : box.xMax;
      final bottom = isNormalized ? box.yMax * size.height : box.yMax;

      final color = box.isFlame ? Colors.redAccent : Colors.amber;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(rect, paint);

      final label =
          '${box.className.toUpperCase()} ${(box.confidence * 100).toStringAsFixed(0)}%';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromLTWH(
        left,
        (top - textPainter.height - 6).clamp(0, size.height),
        textPainter.width + 10,
        textPainter.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = color);
      textPainter.paint(canvas, Offset(bgRect.left + 5, bgRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) =>
      oldDelegate.boxes != boxes;
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
