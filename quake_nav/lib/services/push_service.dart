import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth_service.dart';
import 'notification_service.dart';

class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AuthService _authService = AuthService();

  Future<void> initialize({
    required NotificationService notificationService,
    required void Function(String message) log,
    void Function()? onEvacuationRequested,
  }) async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final user = _authService.currentUser;
    if (user != null) {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _authService.updateCurrentUserFcmToken(token);
        log('FCM token registered for uid=${user.uid}');
      } else {
        log('FCM token unavailable.');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (newToken.isEmpty) {
          return;
        }
        await _authService.updateCurrentUserFcmToken(newToken);
        log('FCM token refreshed.');
      });
    } else {
      log('FCM setup skipped: no signed-in user.');
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await _handleIncomingMessage(
        message: message,
        notificationService: notificationService,
        log: log,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final level = _extractLevel(message) ?? 0;
      if (level >= 5) {
        onEvacuationRequested?.call();
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final level = _extractLevel(initialMessage) ?? 0;
      if (level >= 5) {
        onEvacuationRequested?.call();
      }
    }
  }

  Future<void> _handleIncomingMessage({
    required RemoteMessage message,
    required NotificationService notificationService,
    required void Function(String message) log,
  }) async {
    final level = _extractLevel(message);
    if (level == null) {
      log('FCM message ignored: missing intensity level.');
      return;
    }
    await notificationService.showForLevel(level);
    log('FCM alert received: level=$level');
  }

  int? _extractLevel(RemoteMessage message) {
    final levelText = message.data['level']?.toString();
    final parsedLevel = int.tryParse(levelText ?? '');
    if (parsedLevel != null) {
      return parsedLevel;
    }

    final text = message.data['intensity']?.toString().toLowerCase().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final numericMatch = RegExp(r'(^|\\D)(10|[0-9])(\\D|$)').firstMatch(text);
    if (numericMatch != null) {
      return int.tryParse(numericMatch.group(2)!);
    }
    if (text.contains('system ready')) return 0;
    if (text.contains('barely felt')) return 1;
    if (text.contains('slightly felt')) return 2;
    if (text.contains('weak')) return 3;
    if (text.contains('moderate')) return 4;
    if (text.contains('fairly strong')) return 5;
    if (text.contains('very strong')) return 7;
    if (text == 'strong' || text.contains(' strong')) return 6;
    if (text.contains('destructive')) return 8;
    if (text.contains('devastating')) return 9;
    if (text.contains('catastrophic')) return 10;
    if (text == 'light') return 3;
    if (text.contains('moderately strong')) return 4;
    return null;
  }
}
