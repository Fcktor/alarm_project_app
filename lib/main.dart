import 'package:flutter/material.dart';
import 'screens/alarm_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init(
    onNotificationTap: () {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      bool alreadyOnAlarm = false;
      navigator.popUntil((route) {
        alreadyOnAlarm = route.settings.name == '/alarm';
        return true;
      });

      if (!alreadyOnAlarm) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const AlarmScreen(),
            settings: const RouteSettings(name: '/alarm'),
          ),
        );
      }
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
    );
  }
}