import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _alarmChannelId = 'flood_alarm_channel';
  static const _alarmChannelName = 'Flood Alarm';
  static const _mainAlertId = 1;
  static const _upstreamAlertId = 2;
  static const _manikalAlertId = 3;

  // System alarm URI — plays the device's default alarm ringtone
  static const _alarmSoundUri =
      'content://settings/system/alarm_alert';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create alarm channel once. Android caches channels by ID — sound is
    // locked in on first creation, so use a distinct channel ID from the old one.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _alarmChannelId,
            _alarmChannelName,
            importance: Importance.max,
            sound: UriAndroidNotificationSound(_alarmSoundUri),
            enableVibration: true,
            playSound: true,
          ),
        );
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showThresholdAlert({
    required double currentLevel,
    required double threshold,
  }) async {
    await _plugin.show(
      _mainAlertId,
      'FLOOD ALERT — Kallooppara',
      'Water level ${currentLevel.toStringAsFixed(2)} m has crossed ${threshold.toStringAsFixed(2)} m',
      _alarmDetails(),
    );
  }

  Future<void> showUpstreamAlert({
    required double currentLevel,
    required double threshold,
  }) async {
    await _plugin.show(
      _upstreamAlertId,
      'EARLY WARNING — Upstream Rising',
      'Pullakkayar at ${currentLevel.toStringAsFixed(2)} — Kallooppara may rise soon',
      _alarmDetails(),
    );
  }

  Future<void> showManikalAlert({
    required double currentLevel,
    required double threshold,
  }) async {
    await _plugin.show(
      _manikalAlertId,
      'EARLY WARNING — Manikal Rising',
      'Manikal at ${currentLevel.toStringAsFixed(2)} — Kallooppara may rise soon',
      _alarmDetails(),
    );
  }

  static NotificationDetails _alarmDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _alarmChannelId,
        _alarmChannelName,
        importance: Importance.max,
        priority: Priority.high,
        sound: UriAndroidNotificationSound(_alarmSoundUri),
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
  }
}
