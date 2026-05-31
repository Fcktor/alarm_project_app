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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alarma programada para dentro de 10 segundos'),
                duration: Duration(seconds: 2),
              ),
            );
            await NotificationService.scheduleAlarm(
              const Duration(seconds: 10),
            );
          },
          child: const Text('Set Test Alarm'),
        ),
      ),
    );
  }
}