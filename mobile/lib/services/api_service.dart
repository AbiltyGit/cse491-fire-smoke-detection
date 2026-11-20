import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/camera.dart';
import '../models/detection_event.dart';

/// REST client for the PyroGuard FastAPI backend (`backend/app/api/`).
///
/// Falls back to realistic demo data when the backend is unreachable so
/// the UI and alert workflows can be previewed standalone.
class ApiService {
  String baseUrl;
  bool usingDemoData = false;

  ApiService({this.baseUrl = 'http://10.0.2.2:8000'});

  Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Camera>> fetchCameras() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/cameras'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        usingDemoData = false;
        final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => Camera.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback to demo cameras when backend is offline.
    }
    usingDemoData = true;
    return _demoCameras();
  }

  Future<List<DetectionEvent>> fetchEvents({
    String? eventType,
    String? cameraId,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{'limit': '$limit'};
    if (eventType != null && eventType != 'all') {
      queryParams['event_type'] = eventType;
    }
    if (cameraId != null) {
      queryParams['camera_id'] = cameraId;
    }

    try {
      final uri =
          Uri.parse('$baseUrl/events').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        usingDemoData = false;
        final List<dynamic> list = jsonDecode(res.body) as List<dynamic>;
        return list
            .map((e) => DetectionEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Fallback to demo events when backend is offline.
    }
    usingDemoData = true;
    final demo = _demoEvents();
    if (eventType != null && eventType != 'all') {
      return demo.where((e) => e.eventType == eventType).toList();
    }
    return demo;
  }

  Future<DetectionEvent?> fetchEventById(String eventId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/events/$eventId'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return DetectionEvent.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fallback to demo search.
    }
    for (final ev in _demoEvents()) {
      if (ev.id == eventId) return ev;
    }
    return null;
  }

  /// Registers the device's FCM token with the backend (`user_devices` table).
  /// Note: Endpoint `/devices/register` is planned for the next backend sprint.
  Future<bool> registerFcmToken({
    required String fcmToken,
    required String platform,
    String? userId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/devices/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (userId != null) 'user_id': userId,
              'fcm_token': fcmToken,
              'platform': platform,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Acknowledges a notification/event (`notification_logs.status = 'acknowledged'`).
  Future<bool> acknowledgeEvent(String eventId) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl/events/$eventId/acknowledge'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ---- Demo / Wireframe Preview Data ----

  static List<Camera> _demoCameras() {
    final now = DateTime.now();
    return [
      Camera(
        id: 'cam-001',
        name: 'CAM-01 · Main Warehouse',
        rtspUrl: 'rtsp://192.168.1.101:8554/warehouse',
        location: 'Building A - Ground Floor',
        confThreshold: 0.45,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Camera(
        id: 'cam-002',
        name: 'CAM-02 · Electrical Room',
        rtspUrl: 'rtsp://192.168.1.102:8554/electrical',
        location: 'Building B - Basement',
        confThreshold: 0.50,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Camera(
        id: 'cam-003',
        name: 'CAM-03 · North Courtyard',
        rtspUrl: 'rtsp://192.168.1.103:8554/courtyard',
        location: 'Outdoor - North Gate',
        confThreshold: 0.45,
        isActive: false,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static List<DetectionEvent> _demoEvents() {
    final now = DateTime.now();
    return [
      DetectionEvent(
        id: 'evt-1001',
        cameraId: 'cam-001',
        cameraName: 'CAM-01 · Main Warehouse',
        cameraLocation: 'Building A - Ground Floor',
        eventType: 'both',
        maxConfidence: 0.91,
        frameStreak: 5,
        snapshotPath: null,
        detectedAt: now.subtract(const Duration(minutes: 4)),
        boxes: const [
          DetectionBox(
            id: 'box-1',
            className: 'flame',
            confidence: 0.91,
            xMin: 0.22,
            yMin: 0.42,
            xMax: 0.52,
            yMax: 0.80,
          ),
          DetectionBox(
            id: 'box-2',
            className: 'smoke',
            confidence: 0.84,
            xMin: 0.18,
            yMin: 0.14,
            xMax: 0.64,
            yMax: 0.48,
          ),
        ],
      ),
      DetectionEvent(
        id: 'evt-1002',
        cameraId: 'cam-002',
        cameraName: 'CAM-02 · Electrical Room',
        cameraLocation: 'Building B - Basement',
        eventType: 'smoke',
        maxConfidence: 0.78,
        frameStreak: 4,
        snapshotPath: null,
        detectedAt: now.subtract(const Duration(minutes: 37)),
        boxes: const [
          DetectionBox(
            id: 'box-3',
            className: 'smoke',
            confidence: 0.78,
            xMin: 0.40,
            yMin: 0.20,
            xMax: 0.78,
            yMax: 0.58,
          ),
        ],
      ),
      DetectionEvent(
        id: 'evt-1003',
        cameraId: 'cam-001',
        cameraName: 'CAM-01 · Main Warehouse',
        cameraLocation: 'Building A - Ground Floor',
        eventType: 'flame',
        maxConfidence: 0.86,
        frameStreak: 4,
        snapshotPath: null,
        detectedAt: now.subtract(const Duration(hours: 3, minutes: 12)),
        acknowledged: true,
        boxes: const [
          DetectionBox(
            id: 'box-4',
            className: 'flame',
            confidence: 0.86,
            xMin: 0.55,
            yMin: 0.48,
            xMax: 0.82,
            yMax: 0.82,
          ),
        ],
      ),
    ];
  }
}
