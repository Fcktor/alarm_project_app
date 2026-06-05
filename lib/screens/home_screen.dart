import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

const Color kBackground = Color(0xFFFFF0A0);
const Color kAlarmGold = Color(0xFFFFB300);
const Color kDark = Color(0xFF2D2D2D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<({TimeOfDay time, int alarmId})> _alarms = [];

  Future<void> _addAlarm() async {
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

    final id = await AlarmService.scheduleAlarm(alarmTime);
    if (!mounted) return;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al programar la alarma. Verifica los permisos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final diff = alarmTime.difference(now);
    final mins = diff.inMinutes;
    final label = mins < 60 ? 'en $mins min' : 'en ${diff.inHours}h ${mins % 60}min';

    setState(() => _alarms.add((time: picked, alarmId: id)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarma a las ${picked.format(context)} ($label)'),
        backgroundColor: kAlarmGold,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteAlarm(int index) async {
    await AlarmService.stopAlarm(_alarms[index].alarmId);
    setState(() => _alarms.removeAt(index));
  }

  Future<void> _testNow() async {
    final id = await AlarmService.testAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id != null
            ? 'Alarma de prueba en 5 segundos...'
            : 'Error al programar la prueba.'),
        backgroundColor: id != null ? Colors.green : Colors.red,
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
            tooltip: 'Probar (5 seg)',
            onPressed: _testNow,
          ),
        ],
      ),
      body: _alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_off, size: 80,
                      color: kAlarmGold.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay alarmas programadas',
                    style: TextStyle(fontSize: 16,
                        color: kDark.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _testNow,
                    icon: const Icon(Icons.notifications_active,
                        color: kAlarmGold),
                    label: const Text('Probar ahora (5 seg)',
                        style: TextStyle(color: kAlarmGold)),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kAlarmGold)),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: kAlarmGold, shape: BoxShape.circle),
                      child: const Icon(Icons.alarm,
                          color: Colors.white, size: 24),
                    ),
                    title: Text(
                      alarm.time.format(context),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kDark),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteAlarm(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        backgroundColor: kAlarmGold,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva alarma',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
