import 'package:flutter/material.dart';
import '../services/notification_service.dart';

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
    );
    if (picked == null || !mounted) return;

    // capturamos el texto antes del siguiente await para no usar context después
    final formattedTime = picked.format(context);

    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
    if (alarmTime.isBefore(now)) alarmTime = alarmTime.add(const Duration(days: 1));

    await NotificationService.scheduleAlarm(alarmTime.difference(now));

    if (!mounted) return;
    setState(() => _alarms.add(picked));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alarma programada para las $formattedTime')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm App')),
      body: _alarms.isEmpty
          ? const Center(child: Text('No hay alarmas programadas'))
          : ListView.builder(
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(alarm.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _alarms.removeAt(index)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: const Icon(Icons.add),
      ),
    );
  }
}