import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise.dart';
import '../models/user_model.dart';

class CompleteResult {
  final int pointsEarned;
  final int newTotal;
  final int newStreak;
  final List<Exercise> newlyUnlocked;

  const CompleteResult({
    required this.pointsEarned,
    required this.newTotal,
    required this.newStreak,
    required this.newlyUnlocked,
  });
}

class UserService {
  static final _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users');

  Future<void> createUser({
    required String uid,
    required String displayName,
    required String email,
    required String avatarColor,
  }) async {
    await _col.doc(uid).set(UserModel(
          uid: uid,
          displayName: displayName,
          email: email,
          avatarColor: avatarColor,
        ).toFirestore());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> userStream(String uid) =>
      _col.doc(uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });

  Future<CompleteResult> completeExercise(
      String uid, Exercise exercise) async {
    late CompleteResult result;

    await _db.runTransaction((tx) async {
      final ref = _col.doc(uid);
      final snap = await tx.get(ref);
      final user = UserModel.fromFirestore(snap);

      final earned = exercise.targetReps * exercise.pointsPerRep;
      final oldPoints = user.totalPoints;
      final newPoints = oldPoints + earned;

      final today = DateTime.now();
      final todayDay = DateTime(today.year, today.month, today.day);
      int newStreak = user.currentStreak;

      if (user.lastCompletedDate == null) {
        newStreak = 1;
      } else {
        final last = user.lastCompletedDate!;
        final lastDay = DateTime(last.year, last.month, last.day);
        final diff = todayDay.difference(lastDay).inDays;
        if (diff == 0) {
          // already completed today — keep streak
        } else if (diff == 1) {
          newStreak = user.currentStreak + 1;
        } else {
          newStreak = 1;
        }
      }

      tx.update(ref, {
        'totalPoints': newPoints,
        'currentStreak': newStreak,
        'lastCompletedDate': Timestamp.fromDate(today),
      });

      result = CompleteResult(
        pointsEarned: earned,
        newTotal: newPoints,
        newStreak: newStreak,
        newlyUnlocked: newlyUnlocked(oldPoints, newPoints),
      );
    });

    return result;
  }

  Future<List<UserModel>> getLeaderboard({int limit = 50}) async {
    final snap = await _col
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(UserModel.fromFirestore).toList();
  }
}
