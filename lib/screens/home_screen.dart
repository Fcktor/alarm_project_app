import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/alarm_service.dart';
import '../widgets/wave_painters.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

const _kBg = Color(0xFFF0F0F3);
const _kDark = Color(0xFF0D0D0D);
const _kBlue = Color(0xFF0057FF);

const _kGradients = [
  [Color(0xFFF7971E), Color(0xFFFFD200), Color(0xFFFF6B6B), Color(0xFF9B59B6)],
  [Color(0xFF00C6FB), Color(0xFF005BEA), Color(0xFF4A00E0)],
  [Color(0xFFFF416C), Color(0xFFFF4B2B), Color(0xFF8E2DE2)],
  [Color(0xFF11998E), Color(0xFF38EF7D), Color(0xFF0575E6)],
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<({TimeOfDay time, int alarmId})> _alarms = [];

  List<Color> _gradientFor(int i) => _kGradients[i % _kGradients.length];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final saved = await AlarmService.loadAlarms();
    if (mounted && saved.isNotEmpty) setState(() => _alarms.addAll(saved));
  }

  Future<void> _addAlarm() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kBlue,
            surface: Color(0xFF1A1A2E),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al programar la alarma. Verifica los permisos.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final diff = alarmTime.difference(now);
    final mins = diff.inMinutes;
    final label =
        mins < 60 ? 'en $mins min' : 'en ${diff.inHours}h ${mins % 60}min';

    setState(() => _alarms.add((time: picked, alarmId: id)));
    await AlarmService.saveAlarms(_alarms);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Alarma a las ${picked.format(context)} ($label)'),
      backgroundColor: _kBlue,
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _deleteAlarm(int index) async {
    await AlarmService.stopAlarm(_alarms[index].alarmId);
    setState(() => _alarms.removeAt(index));
    await AlarmService.saveAlarms(_alarms);
  }

  Future<void> _testNow() async {
    final id = await AlarmService.testAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          id != null ? 'Prueba en 5 segundos...' : 'Error al programar prueba.'),
      backgroundColor: id != null ? _kBlue : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? 'Hola, ${user.displayName} 👋'
                              : 'Mis alarmas',
                          style: TextStyle(
                              fontSize: 14,
                              color: _kDark.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mis alarmas${_alarms.isNotEmpty ? ' (${_alarms.length})' : ''}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _kDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Test button
                  GestureDetector(
                    onTap: _testNow,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                          color: _kDark, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            // ── User stats strip ─────────────────────────────────────────────
            if (user != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '⭐ ${user.totalPoints} pts',
                          style: const TextStyle(
                              color: Color(0xFF38EF7D),
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '🔥 ${user.currentStreak}d',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          user.levelName,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Alarm list ───────────────────────────────────────────────────
            Expanded(
              child: _alarms.isEmpty
                  ? _EmptyState(onTest: _testNow)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _alarms.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _AlarmCard(
                          time: _alarms[i].time,
                          gradient: _gradientFor(i),
                          onDelete: () => _deleteAlarm(i),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── Bottom nav ─────────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: _kDark,
        unselectedItemColor: _kDark.withValues(alpha: 0.35),
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
          } else if (i == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarmas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'Ranking'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),

      floatingActionButton: GestureDetector(
        onTap: _addAlarm,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: _kDark,
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('Nueva alarma',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Alarm Card ────────────────────────────────────────────────────────────────

class _AlarmCard extends StatelessWidget {
  final TimeOfDay time;
  final List<Color> gradient;
  final VoidCallback onDelete;

  const _AlarmCard({
    required this.time,
    required this.gradient,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: const SizedBox.expand(
              child: CustomPaint(painter: WavePainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time.format(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Alarma activa',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        Text('Ejercicio aleatorio para apagar',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTest;
  const _EmptyState({required this.onTest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.alarm, size: 36, color: _kDark),
          ),
          const SizedBox(height: 20),
          const Text('Sin alarmas',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _kDark)),
          const SizedBox(height: 6),
          Text('Agrega una alarma para comenzar',
              style:
                  TextStyle(fontSize: 14, color: _kDark.withValues(alpha: 0.4))),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onTest,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color: _kDark.withValues(alpha: 0.18), width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 18, color: _kDark.withValues(alpha: 0.55)),
                  const SizedBox(width: 8),
                  Text('Probar (5 seg)',
                      style: TextStyle(
                          color: _kDark.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
