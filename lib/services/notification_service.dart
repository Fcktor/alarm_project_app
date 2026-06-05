import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static VoidCallback? _onNotificationTap;
  static int _nextId = 0;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static Future init({VoidCallback? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;
    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _onNotificationTap?.call();
      },
    );
  }

  /// Solicita todos los permisos necesarios. Retorna el estado de cada uno.
  static Future<({bool notifications, bool exactAlarms, bool battery})>
      requestPermissions() async {
    final notifGranted =
        await _android?.requestNotificationsPermission() ?? true;
    final exactGranted =
        await _android?.requestExactAlarmsPermission() ?? true;

    // Pide excluir la app de optimización de batería (crítico para alarmas)
    final batteryStatus =
        await Permission.ignoreBatteryOptimizations.request();

    return (
      notifications: notifGranted,
      exactAlarms: exactGranted,
      battery: batteryStatus.isGranted,
    );
  }

  static Future<({bool notifications, bool exactAlarms, bool battery})>
      checkPermissions() async {
    final notifOk = await _android?.areNotificationsEnabled() ?? true;
    final exactOk = await _android?.canScheduleExactNotifications() ?? true;
    final batteryOk = await Permission.ignoreBatteryOptimizations.status;

    return (
      notifications: notifOk,
      exactAlarms: exactOk,
      battery: batteryOk.isGranted,
    );
  }

  static AndroidNotificationDetails _alarmDetails() {
    return const AndroidNotificationDetails(
      'alarm_channel_v2',
      'Alarmas',
      channelDescription: 'Canal para alarmas',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
  }

  static Future showAlarm() async {
    await _notifications.show(
      _nextId++,
      '⏰ ¡Alarma!',
      'Toca para apagar la alarma',
      NotificationDetails(
        android: _alarmDetails(),
        linux: const LinuxNotificationDetails(defaultActionName: 'Open'),
      ),
    );
  }

  /// Devuelve null si se programó OK, o un mensaje de error si falló.
  static Future<String?> scheduleAlarm(Duration fromNow) async {
    try {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(fromNow);

      await _notifications.zonedSchedule(
        _nextId++,
        '⏰ ¡Alarma!',
        'Toca para apagar la alarma',
        scheduledTime,
        NotificationDetails(
          android: _alarmDetails(),
          linux: const LinuxNotificationDetails(defaultActionName: 'Open'),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
