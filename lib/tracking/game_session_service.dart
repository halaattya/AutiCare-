import 'package:cloud_firestore/cloud_firestore.dart';

import 'game_ids.dart';

class GameSessionService {
  static String? _levelKeyForGameId(String gameId) {
    switch (gameId) {
      case GameIds.memory:
        return 'memory';
      case GameIds.shapeMatching:
        return 'match';
      case GameIds.tapTarget:
        return 'tap';

      // ✅ FIX (ONLY FIX):
      // Must match ParentChildProfileScreen + GamesScreen
      case GameIds.communication:
        return 'comm';

      default:
        return null;
    }
  }

  static Future<void> saveSession({
    required String childId,
    required String gameId,
    required DateTime startedAt,
    required DateTime endedAt,
    required bool completed,
    required Map<String, dynamic> metrics,

    // optional – already existed in your logic
    int? levelPlayed,
    int? levelAfter,
  }) async {
    final durationSec = endedAt.difference(startedAt).inSeconds;

    final ref = FirebaseFirestore.instance
        .collection('children')
        .doc(childId)
        .collection('game_sessions');

    await ref.add({
      'gameId': gameId,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'durationSec': durationSec,
      'completed': completed,
      'metrics': metrics,

      if (levelPlayed != null) 'levelPlayed': levelPlayed,
      if (levelAfter != null) 'levelAfter': levelAfter,

      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update current visible level so Parent Profile reflects auto change
    if (levelAfter != null) {
      final key = _levelKeyForGameId(gameId);
      if (key != null) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(childId)
            .set(
          {
            'placement': {
              'currentLevels': {key: levelAfter}
            }
          },
          SetOptions(merge: true),
        );
      }
    }
  }
}
