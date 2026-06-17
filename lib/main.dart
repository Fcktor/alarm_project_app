import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'screens/alarm_screen.dart';
import 'screens/splash_screen.dart';
import 'services/alarm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Alarm.init();
  await AlarmService.init();
  await AlarmService.requestPermissions();
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
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
      title: 'AlarmFit',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057FF)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
