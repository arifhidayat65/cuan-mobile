import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/cuan_api.dart';
import 'push_preferences.dart';

/// Background message handler — must be a top-level function.
/// The OS shows the system-tray notification for messages that carry a
/// notification payload; this just ensures Firebase is initialized.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push notification service (FCM).
///
/// Resilient by design: if Firebase isn't configured yet (no
/// `google-services.json`), [init] silently no-ops and the app runs normally.
class NotificationService {
  static const _channelId = 'cuan_channel';
  static const _channelName = 'Notifikasi Cuan';
  static const _channelDesc =
      'Pengingat budget, transaksi, dan info penting Cuan.';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _firebaseOk = false;
  bool _ready = false;

  /// Whether push is currently enabled per the settings toggle.
  /// Read from persisted preferences on [init]; updated by [setPushEnabled].
  bool _pushEnabled = true;
  bool _pushActive = false;

  /// Persisted toggle state — the settings switch reads/writes through here.
  Future<bool> isPushEnabled() => PushPreferences().isEnabled();

  /// Initialize Firebase, request permission, show foreground heads-up
  /// notifications, and sync the device token to the backend.
  ///
  /// Respects the persisted push toggle: when disabled, Firebase still
  /// initializes (harmless) but no permission is requested and no token is
  /// synced, so the device receives nothing.
  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    _pushEnabled = await PushPreferences().isEnabled();

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase not configured (google-services.json missing) — run without push.
      return;
    }
    _firebaseOk = true;

    if (_pushEnabled) {
      await _activatePush();
    }
  }

  /// Wire up permission, channel, listeners and token sync.
  /// Idempotent — safe to call when re-enabling from settings.
  Future<void> _activatePush() async {
    if (_pushActive) return;
    _pushActive = true;

    final messaging = FirebaseMessaging.instance;

    // Android 13+ runtime permission.
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground heads-up display via local notifications.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initial token sync (no-op if not logged in — syncToken() retries after login).
    await syncToken();
    messaging.onTokenRefresh.listen(_sendTokenToBackend);
  }

  /// Apply the settings toggle: persists the preference and actually
  /// controls push. Disabling unregisters the device token (best-effort)
  /// so no pushes arrive; enabling re-activates permission + token sync.
  Future<void> setPushEnabled(bool enabled) async {
    await PushPreferences().setEnabled(enabled);
    _pushEnabled = enabled;
    if (enabled) {
      if (!_firebaseOk) {
        try {
          await Firebase.initializeApp();
          _firebaseOk = true;
        } catch (_) {
          // Firebase not configured — preference saved; nothing to activate.
          return;
        }
      }
      await _activatePush();
      await syncToken();
    } else {
      await onLogout();
    }
  }

  /// Push the current FCM token to the backend. Safe to call when logged out
  /// (the request 401s and is swallowed) — call again after login.
  Future<void> syncToken() async {
    if (!_firebaseOk || !_pushEnabled) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (_) {
      // Non-fatal: will retry on next app start / login.
    }
  }

  /// Unregister the device token before logout (needs an active session,
  /// so call this BEFORE api.signOut()).
  Future<void> onLogout() async {
    if (!_firebaseOk) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.unregisterFcmToken(token);
      }
    } catch (_) {
      // Best effort — stale tokens are harmless.
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await api.registerFcmToken(token);
    } catch (_) {
      // Not logged in yet or offline — syncToken() retries after login.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    if (!_pushEnabled) return;
    final notification = message.notification;
    if (notification == null) return;
    await _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'],
    );
  }
}

final notifications = NotificationService();
