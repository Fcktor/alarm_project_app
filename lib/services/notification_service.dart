import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);
  }

  static Future showAlarm() async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '⏰ Alarm!',
      'Wake up and complete your task',
      details,
    );
  }
}