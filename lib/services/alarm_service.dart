import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static int _nextId = 1;

  /// Pide permisos de notificación y optimización de batería.
  static Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  static AlarmSettings _buildSettings({
    required int id,
    required DateTime dateTime,
  }) {
    return AlarmSettings(
      id: id,
      dateTime: dateTime,
      // null = usa el sonido de alarma predeterminado del dispositivo
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      volumeSettings: const VolumeSettings.fixed(volume: 1.0),
      notificationSettings: const NotificationSettings(
        title: '⏰ ¡Alarma!',
        body: 'Toca para apagar la alarma',
        stopButton: 'Apagar',
      ),
    );
  }

  /// Programa una alarma y devuelve el ID asignado, o null si falla.
  static Future<int?> scheduleAlarm(DateTime dateTime) async {
    try {
      final id = _nextId++;
      await Alarm.set(alarmSettings: _buildSettings(id: id, dateTime: dateTime));
      return id;
    } catch (e) {
      return null;
    }
  }

  /// Dispara una alarma de prueba en 5 segundos.
  static Future<int?> testAlarm() async {
    return scheduleAlarm(DateTime.now().add(const Duration(seconds: 5)));
  }

  /// Detiene la alarma con el ID dado.
  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
  }
}
