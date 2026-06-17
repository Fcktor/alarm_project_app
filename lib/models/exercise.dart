import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String name;
  final String emoji;
  final int difficulty;
  final int targetReps;
  final int pointsPerRep;
  final int unlockThreshold;
  final bool isAutoDetected;

  const Exercise({
    required this.id,
    required this.name,
    required this.emoji,
    required this.difficulty,
    required this.targetReps,
    required this.pointsPerRep,
    required this.unlockThreshold,
    this.isAutoDetected = false,
  });

  int get totalPoints => targetReps * pointsPerRep;

  String get tierName {
    if (unlockThreshold >= 700) return 'Élite';
    if (unlockThreshold >= 300) return 'Avanzado';
    if (unlockThreshold >= 100) return 'Medio';
    return 'Básico';
  }

  Color get tierColor {
    if (unlockThreshold >= 700) return const Color(0xFFFF416C);
    if (unlockThreshold >= 300) return const Color(0xFFF7971E);
    if (unlockThreshold >= 100) return const Color(0xFF0057FF);
    return const Color(0xFF11998E);
  }
}

const List<Exercise> kExercises = [
  // ── Básico (0 pts) ───────────────────────────────────────────────────────────
  Exercise(
    id: 'push_ups',
    name: 'Flexiones',
    emoji: '💪',
    difficulty: 1,
    targetReps: 10,
    pointsPerRep: 1,
    unlockThreshold: 0,
    isAutoDetected: true,
  ),
  Exercise(
    id: 'sit_ups',
    name: 'Abdominales',
    emoji: '🔥',
    difficulty: 1,
    targetReps: 15,
    pointsPerRep: 1,
    unlockThreshold: 0,
  ),
  Exercise(
    id: 'jumping_jacks',
    name: 'Jumping Jacks',
    emoji: '⚡',
    difficulty: 1,
    targetReps: 20,
    pointsPerRep: 1,
    unlockThreshold: 0,
  ),
  Exercise(
    id: 'squats',
    name: 'Sentadillas',
    emoji: '🦵',
    difficulty: 1,
    targetReps: 15,
    pointsPerRep: 1,
    unlockThreshold: 0,
  ),
  Exercise(
    id: 'burpees',
    name: 'Burpees',
    emoji: '🏃',
    difficulty: 2,
    targetReps: 10,
    pointsPerRep: 2,
    unlockThreshold: 0,
  ),

  // ── Medio (100 pts) ──────────────────────────────────────────────────────────
  Exercise(
    id: 'diamond_push_ups',
    name: 'Flexiones Diamante',
    emoji: '💎',
    difficulty: 2,
    targetReps: 10,
    pointsPerRep: 2,
    unlockThreshold: 100,
    isAutoDetected: true,
  ),
  Exercise(
    id: 'dips',
    name: 'Fondos en Silla',
    emoji: '🪑',
    difficulty: 2,
    targetReps: 12,
    pointsPerRep: 2,
    unlockThreshold: 100,
  ),
  Exercise(
    id: 'lunges',
    name: 'Zancadas',
    emoji: '🚶',
    difficulty: 2,
    targetReps: 20,
    pointsPerRep: 2,
    unlockThreshold: 100,
  ),
  Exercise(
    id: 'plank',
    name: 'Plancha Isométrica',
    emoji: '🧘',
    difficulty: 2,
    targetReps: 1,
    pointsPerRep: 5,
    unlockThreshold: 100,
  ),

  // ── Avanzado (300 pts) ───────────────────────────────────────────────────────
  Exercise(
    id: 'pull_ups',
    name: 'Dominadas',
    emoji: '🏋️',
    difficulty: 4,
    targetReps: 5,
    pointsPerRep: 4,
    unlockThreshold: 300,
  ),
  Exercise(
    id: 'wall_handstand',
    name: 'Pino contra Pared',
    emoji: '🙃',
    difficulty: 4,
    targetReps: 1,
    pointsPerRep: 10,
    unlockThreshold: 300,
  ),
  Exercise(
    id: 'pistol_squat',
    name: 'Pistol Squat',
    emoji: '🎯',
    difficulty: 3,
    targetReps: 5,
    pointsPerRep: 4,
    unlockThreshold: 300,
  ),

  // ── Élite (700 pts) ──────────────────────────────────────────────────────────
  Exercise(
    id: 'handstand',
    name: 'Pino Libre',
    emoji: '🤸',
    difficulty: 5,
    targetReps: 1,
    pointsPerRep: 15,
    unlockThreshold: 700,
  ),
  Exercise(
    id: 'planche',
    name: 'Planche',
    emoji: '✈️',
    difficulty: 5,
    targetReps: 1,
    pointsPerRep: 20,
    unlockThreshold: 700,
  ),
  Exercise(
    id: 'one_arm_push_up',
    name: 'Flexión a Una Mano',
    emoji: '☝️',
    difficulty: 5,
    targetReps: 3,
    pointsPerRep: 8,
    unlockThreshold: 700,
  ),
  Exercise(
    id: 'archer_push_up',
    name: 'Flexión Arquero',
    emoji: '🏹',
    difficulty: 4,
    targetReps: 5,
    pointsPerRep: 6,
    unlockThreshold: 700,
  ),
  Exercise(
    id: 'muscle_up',
    name: 'Muscle-Up',
    emoji: '🚀',
    difficulty: 5,
    targetReps: 3,
    pointsPerRep: 10,
    unlockThreshold: 700,
  ),
];

const List<int> kUnlockThresholds = [0, 100, 300, 700];

List<Exercise> unlockedExercises(int totalPoints) =>
    kExercises.where((e) => totalPoints >= e.unlockThreshold).toList();

List<Exercise> newlyUnlocked(int oldPoints, int newPoints) =>
    kExercises
        .where((e) =>
            e.unlockThreshold > 0 &&
            oldPoints < e.unlockThreshold &&
            newPoints >= e.unlockThreshold)
        .toList();
