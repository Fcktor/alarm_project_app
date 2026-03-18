import 'package:flutter/material.dart';
import 'package:alarm_object_app/services/notification_service.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarm App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await NotificationService.showAlarm();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AlarmScreen(),
              ),
            );
          },
          child: const Text('Set Test Alarm'),
        ),
      ),
    );
  }
}