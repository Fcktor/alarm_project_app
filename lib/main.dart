import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'screens/alarm_screen.dart';
import 'screens/home_screen.dart';
import 'services/alarm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await AlarmService.requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AlarmSet>? _ringSub;

  @override
  void initState() {
    super.initState();
    _ringSub = Alarm.ringing.listen(_onRinging);
    // Si ya hay una alarma sonando al abrir la app (lanzada desde notificación)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ringing = Alarm.ringing.value.alarms;
      if (ringing.isNotEmpty) _openAlarmScreen(ringing.first.id);
    });
  }

  void _onRinging(AlarmSet alarmSet) {
    if (alarmSet.alarms.isNotEmpty) {
      _openAlarmScreen(alarmSet.alarms.first.id);
    }
  }

  void _openAlarmScreen(int alarmId) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    bool alreadyOpen = false;
    navigator.popUntil((route) {
      alreadyOpen = route.settings.name == '/alarm';
      return true;
    });

    if (!alreadyOpen) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => AlarmScreen(alarmId: alarmId),
          settings: const RouteSettings(name: '/alarm'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ringSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}
