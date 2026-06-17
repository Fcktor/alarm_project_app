import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise.dart';

const List<String> kAvatarColors = [
  '#FF6B6B', '#FFA500', '#FFD200', '#00C853', '#0057FF',
  '#9B59B6', '#E91E63', '#00BCD4', '#795548', '#607D8B',
];

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final int totalPoints;
  final int currentStreak;
  final DateTime? lastCompletedDate;
  final String avatarColor;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.lastCompletedDate,
    this.avatarColor = '#0057FF',
  });

  int get level {
    if (totalPoints >= 700) return 4;
    if (totalPoints >= 300) return 3;
    if (totalPoints >= 100) return 2;
    return 1;
  }

  String get levelName {
    switch (level) {
      case 4: return 'Élite';
      case 3: return 'Avanzado';
      case 2: return 'Intermedio';
      default: return 'Principiante';
    }
  }

  int get nextLevelThreshold {
    const thresholds = [100, 300, 700];
    if (level >= 4) return 0;
    return thresholds[level - 1];
  }

  double get levelProgress {
    if (level >= 4) return 1.0;
    final thresholds = [0, 100, 300, 700];
    final from = thresholds[level - 1];
    final to = thresholds[level];
    return (totalPoints - from) / (to - from);
  }

  List<Exercise> get unlocked => unlockedExercises(totalPoints);

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return UserModel(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      email: d['email'] as String? ?? '',
      totalPoints: d['totalPoints'] as int? ?? 0,
      currentStreak: d['currentStreak'] as int? ?? 0,
      lastCompletedDate:
          (d['lastCompletedDate'] as Timestamp?)?.toDate(),
      avatarColor: d['avatarColor'] as String? ?? '#0057FF',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'totalPoints': totalPoints,
        'currentStreak': currentStreak,
        'lastCompletedDate': lastCompletedDate != null
            ? Timestamp.fromDate(lastCompletedDate!)
            : null,
        'avatarColor': avatarColor,
      };

  UserModel copyWith({
    String? displayName,
    int? totalPoints,
    int? currentStreak,
    DateTime? lastCompletedDate,
    String? avatarColor,
  }) =>
      UserModel(
        uid: uid,
        displayName: displayName ?? this.displayName,
        email: email,
        totalPoints: totalPoints ?? this.totalPoints,
        currentStreak: currentStreak ?? this.currentStreak,
        lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
        avatarColor: avatarColor ?? this.avatarColor,
      );
}
