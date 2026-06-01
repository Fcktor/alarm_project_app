import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static VoidCallback? _onNotificationTap;
  static int _nextId = 0;

  static Future init({VoidCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;
    tz_data.initializeTimeZones();

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
      playSound: true,
      enableVibration: true,
    );

    const linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Open notification',
    );

    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notifications.show(
      _nextId++,
      '⏰ Alarm!',
      'Wake up and complete your task',
      details,
    );
  }

  static Future scheduleAlarm(Duration fromNow) async {
    final scheduledTime = tz.TZDateTime.now(tz.local).add(fromNow);

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
    );
    const linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Open notification',
    );
    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _notifications.zonedSchedule(
      _nextId++,
      '⏰ Alarm!',
      'Wake up and complete your task',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}