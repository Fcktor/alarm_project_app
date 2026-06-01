import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked == null || !context.mounted) return;

            final now = DateTime.now();
            var alarmTime = DateTime(
              now.year, now.month, now.day,
              picked.hour, picked.minute,
            );

            if (alarmTime.isBefore(now)) {
              alarmTime = alarmTime.add(const Duration(days: 1));
            }

            final delay = alarmTime.difference(now);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Alarma programada para las ${picked.format(context)}'),
                duration: const Duration(seconds: 2),
              ),
            );
            await NotificationService.scheduleAlarm(delay);
          },
          child: const Text('Nueva alarma'),
        ),
      ),
    );
  }
}