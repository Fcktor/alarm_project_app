import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F0F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 28),
              _Header(user: user, hexToColor: _hexToColor),
              const SizedBox(height: 24),
              _LevelCard(user: user),
              const SizedBox(height: 20),
              _StatsRow(user: user),
              const SizedBox(height: 28),
              const Text(
                'Ejercicios desbloqueados',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D)),
              ),
              const SizedBox(height: 12),
              _ExerciseGrid(user: user),
              const SizedBox(height: 28),
              const Text(
                'Próximos desbloqueos',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D0D0D)),
              ),
              const SizedBox(height: 12),
              _LockedList(user: user),
              const SizedBox(height: 32),
              _SignOutButton(context: context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final UserModel user;
  final Color Function(String) hexToColor;

  const _Header({required this.user, required this.hexToColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: hexToColor(user.avatarColor),
          child: Text(
            user.displayName.isNotEmpty
                ? user.displayName[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D0D0D)),
              ),
              Text(
                user.levelName,
                style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF0D0D0D).withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Level card ────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  final UserModel user;
  const _LevelCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isMaxLevel = user.level >= 4;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel ${user.level} — ${user.levelName}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                '${user.totalPoints} pts',
                style: const TextStyle(
                    color: Color(0xFF38EF7D),
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: user.levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF38EF7D)),
            ),
          ),
          if (!isMaxLevel) ...[
            const SizedBox(height: 8),
            Text(
              'Faltan ${user.nextLevelThreshold - user.totalPoints} pts para el siguiente nivel',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserModel user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(label: 'Racha', value: '🔥 ${user.currentStreak}d'),
        const SizedBox(width: 12),
        _StatBox(
            label: 'Ejercicios',
            value: '💪 ${user.unlocked.length}/${kExercises.length}'),
        const SizedBox(width: 12),
        _StatBox(label: 'Puntos', value: '⭐ ${user.totalPoints}'),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF0D0D0D).withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }
}

// ── Exercise grid ─────────────────────────────────────────────────────────────

class _ExerciseGrid extends StatelessWidget {
  final UserModel user;
  const _ExerciseGrid({required this.user});

  @override
  Widget build(BuildContext context) {
    final exercises = user.unlocked;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: exercises.length,
      itemBuilder: (_, i) {
        final e = exercises[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(e.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

// ── Locked list ───────────────────────────────────────────────────────────────

class _LockedList extends StatelessWidget {
  final UserModel user;
  const _LockedList({required this.user});

  @override
  Widget build(BuildContext context) {
    final locked =
        kExercises.where((e) => user.totalPoints < e.unlockThreshold).toList();
    if (locked.isEmpty) {
      return const Text(
        '🏆 ¡Desbloqueaste todos los ejercicios!',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
    }
    return Column(
      children: locked.map((e) {
        final missing = e.unlockThreshold - user.totalPoints;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(e.emoji,
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.black.withValues(alpha: 0.3))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D0D0D)
                                .withValues(alpha: 0.5))),
                    Text('Faltan $missing pts',
                        style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF0D0D0D)
                                .withValues(alpha: 0.4))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: e.tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(e.tierName,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: e.tierColor)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Sign out ──────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final BuildContext context;
  const _SignOutButton({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (!ctx.mounted) return;
        ctx.read<UserProvider>().clear();
        Navigator.pushAndRemoveUntil(
          ctx,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Cerrar sesión',
          style: TextStyle(
              color: Colors.red, fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
