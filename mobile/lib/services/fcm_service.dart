import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background FCM handler required by `firebase_messaging`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config files may not yet be present in local dev.
  }
  debugPrint('[FCM Background] Message ID: ${message.messageId}');
}

enum FcmConnectionState {
  uninitialized,
  ready,
  permissionDenied,
  configMissing,
  error,
}

/// Manages Firebase Cloud Messaging lifecycle, permissions, token sync,
/// and foreground high-priority fire/smoke alert banners.
class FcmService {
  static const String _alertChannelId = 'pyroguard_fire_alerts';
  static const String _alertChannelName = 'Fire & Smoke Early Warnings';
  static const String _alertChannelDescription =
      'High-priority real-time alerts dispatched when YOLO + temporal filter confirms fire or smoke.';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FcmConnectionState state = FcmConnectionState.uninitialized;
  String? fcmToken;
  String statusMessage = 'Not initialized';

  final StreamController<Map<String, dynamic>> _alertTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  Stream<Map<String, dynamic>> get onAlertTapped => _alertTapController.stream;
  Stream<RemoteMessage> get onForegroundAlert =>
      _foregroundMessageController.stream;

  Future<void> initialize({
    Future<void> Function(String token, String platform)? onTokenReady,
  }) async {
    await _initLocalNotifications();

    try {
      await Firebase.initializeApp();
    } catch (e) {
      state = FcmConnectionState.configMissing;
      statusMessage =
          'Firebase config missing (google-services.json / GoogleService-Info.plist). Running in local preview mode.';
      debugPrint('[FCM] $statusMessage ($e)');
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        state = FcmConnectionState.permissionDenied;
        statusMessage = 'Notification permission denied by user.';
        return;
      }

      fcmToken = await messaging.getToken();
      final platform = _detectPlatform();

      if (fcmToken != null && onTokenReady != null) {
        await onTokenReady(fcmToken!, platform);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        fcmToken = newToken;
        if (onTokenReady != null) {
          await onTokenReady(newToken, platform);
        }
      });

      // Foreground alerts -> show local high-priority notification banner.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _foregroundMessageController.add(message);
        _showLocalAlert(
          title: message.notification?.title ?? 'Fire / Smoke Alert',
          body: message.notification?.body ??
              'Detection confirmed by temporal filter.',
          eventId: message.data['event_id'] as String?,
        );
      });

      // User tapped notification while app was in background.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _alertTapController.add(message.data);
      });

      // User launched app from terminated state via notification tap.
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _alertTapController.add(initialMessage.data);
      }

      state = FcmConnectionState.ready;
      statusMessage = 'Connected to Firebase Cloud Messaging.';
    } catch (e) {
      state = FcmConnectionState.error;
      statusMessage = 'FCM initialization error: $e';
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _alertTapController.add({'event_id': response.payload});
          }
        },
      );

      const androidChannel = AndroidNotificationChannel(
        _alertChannelId,
        _alertChannelName,
        description: _alertChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    } catch (e) {
      debugPrint('[LocalNotifications] Init skipped: $e');
    }
  }

  Future<void> _showLocalAlert({
    required String title,
    required String body,
    String? eventId,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alertChannelId,
        _alertChannelName,
        channelDescription: _alertChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'PyroGuard Alert',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: eventId,
      );
    } catch (e) {
      debugPrint('[LocalNotifications] Display skipped: $e');
    }
  }

  /// Triggers a local simulated fire alert (useful for meetings & UI demos).
  Future<void> triggerSimulatedAlert({
    String eventId = 'evt-1001',
    String cameraName = 'CAM-01 · Main Warehouse',
  }) async {
    await _showLocalAlert(
      title: '🔥 FIRE & SMOKE DETECTED',
      body: '$cameraName · 91% confidence (5-frame streak)',
      eventId: eventId,
    );
  }

  String _detectPlatform() {
    if (kIsWeb) return 'android';
    try {
      if (Platform.isIOS) return 'ios';
    } catch (_) {}
    return 'android';
  }

  void dispose() {
    _alertTapController.close();
    _foregroundMessageController.close();
  }
}
