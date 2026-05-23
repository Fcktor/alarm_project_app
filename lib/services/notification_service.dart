import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static VoidCallback? _onNotificationTap;

  static Future init({VoidCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open notification');

    const settings = InitializationSettings(
      android: android,
      linux: linux,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call();
      },
    );
  }

  static Future showAlarm() async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    const linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Open notification',
    );

    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      0,
      '⏰ Alarm!',
      'Wake up and complete your task',
      details,
    );
  }
}