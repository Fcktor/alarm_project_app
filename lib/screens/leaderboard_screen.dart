import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = UserService().getLeaderboard();
  }

  Color _hexToColor(String hex) =>
      Color(int.parse(hex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏆 Ranking',
                      style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF0D0D0D).withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text(
                    'Global',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D0D0D),
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<UserModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar el ranking.\nVerifica tu conexión.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFF0D0D0D).withValues(alpha: 0.5)),
                      ),
                    );
                  }
                  final users = snap.data ?? [];
                  if (users.isEmpty) {
                    return const Center(
                      child: Text('Aún no hay usuarios en el ranking.'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _future = UserService().getLeaderboard();
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: users.length,
                      itemBuilder: (_, i) =>
                          _RankRow(rank: i + 1, user: users[i],
                              hexToColor: _hexToColor),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final UserModel user;
  final Color Function(String) hexToColor;

  const _RankRow({
    required this.rank,
    required this.user,
    required this.hexToColor,
  });

  String get _medal {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '$rank';
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3
            ? const Color(0xFF0D0D0D)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isTop3 ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _medal,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isTop3 ? 22 : 16,
                  fontWeight: FontWeight.w800,
                  color: isTop3 ? Colors.white : const Color(0xFF0D0D0D)),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: hexToColor(user.avatarColor),
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isTop3 ? Colors.white : const Color(0xFF0D0D0D)),
                ),
                Text(
                  user.levelName,
                  style: TextStyle(
                      fontSize: 12,
                      color: isTop3
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF0D0D0D).withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.totalPoints}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isTop3
                        ? const Color(0xFF38EF7D)
                        : const Color(0xFF0057FF)),
              ),
              Text(
                'pts',
                style: TextStyle(
                    fontSize: 11,
                    color: isTop3
                        ? Colors.white.withValues(alpha: 0.4)
                        : const Color(0xFF0D0D0D).withValues(alpha: 0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
