import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../services/api_service.dart';

/// Displays configured RTSP surveillance cameras and their monitoring status.
class CamerasScreen extends StatefulWidget {
  final ApiService apiService;

  const CamerasScreen({super.key, required this.apiService});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  bool _loading = true;
  List<Camera> _cameras = [];

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() => _loading = true);
    final cameras = await widget.apiService.fetchCameras();
    if (!mounted) return;
    setState(() {
      _cameras = cameras;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadCameras,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cameras.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final cam = _cameras[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: cam.isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.2),
                child: Icon(
                  cam.isActive ? Icons.videocam : Icons.videocam_off,
                  color: cam.isActive ? Colors.green : Colors.grey,
                ),
              ),
              title: Text(
                cam.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cam.location != null) ...[
                    const SizedBox(height: 4),
                    Text(cam.location!),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Threshold: ${(cam.confThreshold * 100).toStringAsFixed(0)}%  •  ${cam.rtspUrl}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              trailing: Chip(
                label: Text(cam.isActive ? 'ONLINE' : 'PAUSED'),
                backgroundColor: cam.isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: cam.isActive ? Colors.green.shade700 : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
