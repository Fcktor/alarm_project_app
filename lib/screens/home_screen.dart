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

    final formattedTime = picked.format(context);

    final now = DateTime.now();
    var alarmTime =
        DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (alarmTime.isBefore(now)) alarmTime = alarmTime.add(const Duration(days: 1));

    await NotificationService.scheduleAlarm(alarmTime.difference(now));

    if (!mounted) return;
    setState(() => _alarms.add(picked));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alarma programada para las $formattedTime'),
        backgroundColor: kAlarmGold,
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _alarms.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_off, size: 80, color: kAlarmGold.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay alarmas programadas',
                    style: TextStyle(
                      fontSize: 16,
                      color: kDark.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kAlarmGold.withOpacity(0.15),
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
                        color: kAlarmGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.alarm, color: Colors.white, size: 24),
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
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _alarms.removeAt(index)),
                    ),
                  ),
                );
              },
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
