import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/quake_intensity.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String advisoryChannelId = 'quake_advisory_v3';
  // Bumped channel ID so Android recreates channel with fresh settings.
  static const String evacuationChannelId = 'quake_evac_v4';
  static const RawResourceAndroidNotificationSound _evacAlarmSound =
      RawResourceAndroidNotificationSound('evac_alarm');

  Future<void> init({
    required void Function(String? payload) onSelectNotification,
  }) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings,
        onDidReceiveNotificationResponse: (response) {
      onSelectNotification(response.payload);
    });

    const advisoryChannel = AndroidNotificationChannel(
      advisoryChannelId,
      'Advisory Alerts',
      description: 'Intensity 1-4 earthquake notifications',
      importance: Importance.defaultImportance,
    );

    const evacuationChannel = AndroidNotificationChannel(
      evacuationChannelId,
      'Evacuation Alerts',
      description: 'Intensity 5-10 evacuation alarms',
      importance: Importance.max,
      sound: _evacAlarmSound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(advisoryChannel);
    await androidPlugin?.createNotificationChannel(evacuationChannel);
  }

  Future<void> showForIntensity(QuakeIntensity intensity) async {
    final level = _levelOf(intensity);
    await showForLevel(level);
  }

  Future<void> showForLevel(int? level) async {
    if (level == null) {
      return;
    }
    if (level == 0) {
      return;
    }
    if (level <= 4) {
      await _plugin.cancel(1002);
      await _showAdvisoryNotification(level);
      return;
    }
    if (level >= 5) {
      await _showEvacuationAlert(level);
    }
  }

  Future<void> _showAdvisoryNotification(int level) async {
    const androidDetails = AndroidNotificationDetails(
      advisoryChannelId,
      'Advisory Alerts',
      channelDescription: 'Intensity 1-4 earthquake notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1001,
      'Earthquake Advisory',
      'Intensity $level detected. Stay alert and monitor updates.',
      details,
      payload: 'light',
    );
  }

  Future<void> _showEvacuationAlert(int level) async {
    final vibrationPattern = level >= 8
        ? Int64List.fromList([
            0,
            1000,
            120,
            1200,
            120,
            1400,
            120,
            1600,
            120,
            1800,
          ])
        : Int64List.fromList([
            0,
            700,
            120,
            850,
            120,
            1000,
            120,
            1150,
            120,
            1300,
          ]);
    final androidDetails = AndroidNotificationDetails(
      evacuationChannelId,
      'Evacuation Alerts',
      channelDescription: 'Intensity 5-10 evacuation alarms',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.call,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: _evacAlarmSound,
      ongoing: false,
      autoCancel: false,
    );
    final details = NotificationDetails(android: androidDetails);

    // Force retrigger so vibration/sound fire again even if previous alert exists.
    await _plugin.cancel(1002);
    await _plugin.show(
      1002,
      'Evacuate Now',
      'Intensity $level detected. Open route and evacuate immediately.',
      details,
      payload: 'evacuation',
    );
  }

  int? _levelOf(QuakeIntensity intensity) {
    final name = intensity.name.toLowerCase();
    if (name == 'unknown') {
      return null;
    }
    if (name.startsWith('level')) {
      return int.tryParse(name.substring(5));
    }
    // Backward compatibility with older enum names.
    if (name == 'light') return 3;
    if (name == 'moderate' || name == 'moderatelystrong') return 4;
    if (name == 'strong') return 6;
    return null;
  }
}
