import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService {
  static int _nextId = 1;
  static const _kNextIdKey = 'alarm_next_id';
  static const _kAlarmsKey = 'alarm_list';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _nextId = prefs.getInt(_kNextIdKey) ?? 1;
  }

  static Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.camera.request();
  }

  static AlarmSettings _buildSettings({
    required int id,
    required DateTime dateTime,
  }) {
    return AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0),
      notificationSettings: const NotificationSettings(
        title: '⏰ ¡Alarma!',
        body: 'Toca para abrir y apaga con planchas',
      ),
    );
  }

  static Future<int?> scheduleAlarm(DateTime dateTime) async {
    try {
      final id = _nextId++;
      await Alarm.set(alarmSettings: _buildSettings(id: id, dateTime: dateTime));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kNextIdKey, _nextId);
      return id;
    } catch (e) {
      return null;
    }
  }

  static Future<int?> testAlarm() async {
    return scheduleAlarm(DateTime.now().add(const Duration(seconds: 5)));
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }

  static Future<void> saveAlarms(
      List<({TimeOfDay time, int alarmId})> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final data = alarms
        .map((a) => {'h': a.time.hour, 'm': a.time.minute, 'id': a.alarmId})
        .toList();
    await prefs.setString(_kAlarmsKey, jsonEncode(data));
  }

  static Future<List<({TimeOfDay time, int alarmId})>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAlarmsKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list
        .map((m) => (
              time: TimeOfDay(hour: m['h'] as int, minute: m['m'] as int),
              alarmId: m['id'] as int,
            ))
        .toList();
  }
}
