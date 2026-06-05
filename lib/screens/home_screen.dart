import 'package:flutter/material.dart';
import '../services/notification_service.dart';

const Color kBackground = Color(0xFFFFF0A0);
const Color kAlarmGold = Color(0xFFFFB300);
const Color kDark = Color(0xFF2D2D2D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<TimeOfDay> _alarms = [];
  bool _notifOk = true;
  bool _exactOk = true;
  bool _batteryOk = true;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    final perms = await NotificationService.requestPermissions();
    if (mounted) {
      setState(() {
        _notifOk = perms.notifications;
        _exactOk = perms.exactAlarms;
        _batteryOk = perms.battery;
      });
    }
  }

  Future<void> _addAlarm() async {
    if (!_notifOk || !_exactOk || !_batteryOk) {
      await _initPermissions();
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kAlarmGold,
            onPrimary: Colors.white,
            surface: kBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final now = DateTime.now();
    var alarmTime =
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (alarmTime.isBefore(now)) alarmTime = alarmTime.add(const Duration(days: 1));

    final error = await NotificationService.scheduleAlarm(alarmTime.difference(now));

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al programar alarma: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    setState(() => _alarms.add(picked));

    // Calcula cuántos minutos faltan para confirmar al usuario
    final diff = alarmTime.difference(now);
    final mins = diff.inMinutes;
    final label = mins < 60
        ? 'en $mins min'
        : 'en ${diff.inHours}h ${mins % 60}min';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Alarma a las ${picked.format(context)} ($label)'),
        backgroundColor: kAlarmGold,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _testNow() async {
    if (!_notifOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permiso de notificaciones no concedido. Actívalo en Ajustes.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await NotificationService.showAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Notificación enviada! Revisa el panel de notificaciones.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kAlarmGold,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Mis alarmas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            tooltip: 'Probar ahora',
            onPressed: _testNow,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_notifOk || !_exactOk || !_batteryOk)
            _PermissionBanner(
              notifOk: _notifOk,
              exactOk: _exactOk,
              batteryOk: _batteryOk,
              onTap: _initPermissions,
            ),
          Expanded(
            child: _alarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alarm_off,
                          size: 80,
                          color: kAlarmGold.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay alarmas programadas',
                          style: TextStyle(
                            fontSize: 16,
                            color: kDark.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _testNow,
                          icon: const Icon(Icons.notifications_active,
                              color: kAlarmGold),
                          label: const Text(
                            'Probar notificación ahora',
                            style: TextStyle(color: kAlarmGold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: kAlarmGold),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alarms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kAlarmGold.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: kAlarmGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alarm,
                                color: Colors.white, size: 24),
                          ),
                          title: Text(
                            alarm.format(context),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: kDark,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _alarms.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        backgroundColor: kAlarmGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva alarma', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final bool notifOk;
  final bool exactOk;
  final bool batteryOk;
  final VoidCallback onTap;

  const _PermissionBanner({
    required this.notifOk,
    required this.exactOk,
    required this.batteryOk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final msg = !notifOk
        ? 'Permiso de notificaciones requerido'
        : !exactOk
            ? 'Permiso de alarmas exactas requerido (Ajustes → Alarmas y recordatorios)'
            : 'Optimización de batería activa — la alarma puede no sonar. Toca para desactivarla.';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const Text(
              'Conceder',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
