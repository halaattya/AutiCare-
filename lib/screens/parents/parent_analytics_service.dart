import 'package:cloud_firestore/cloud_firestore.dart';
import '../../tracking/active_child_provider.dart';
import '../../tracking/game_definitions.dart';
import '../../tracking/game_ids.dart';

class ParentGameStats {
  final String gameId;
  final String title;

  final int plays7d;
  final int drops7d;
  final int totalTimeSec7d;
  final double completionRate7d; // 0..1

  final double? primaryAvg7d;
  final double? secondaryAvg7d;

  final double? improvementPercent; // recent 7d vs previous 7d (primary metric)

  const ParentGameStats({
    required this.gameId,
    required this.title,
    required this.plays7d,
    required this.drops7d,
    required this.totalTimeSec7d,
    required this.completionRate7d,
    required this.primaryAvg7d,
    required this.secondaryAvg7d,
    required this.improvementPercent,
  });
}

class ParentOverviewSummary {
  final int totalTimeSec7d;

  final String? favoriteGameTitle;
  final String? droppedGameTitle;

  final String? topImprovedGameTitle;
  final double? topImprovedPercent;

  final List<ParentGameStats> games;

  const ParentOverviewSummary({
    required this.totalTimeSec7d,
    required this.favoriteGameTitle,
    required this.droppedGameTitle,
    required this.topImprovedGameTitle,
    required this.topImprovedPercent,
    required this.games,
  });
}

class ParentAnalyticsService {
  // ✅ FIX: metric reader with safe fallbacks (only affects Communication game)
  static num? _readMetric(Map<String, dynamic> metrics, String key, String gameId) {
    final v = metrics[key];
    if (v is num) return v;

    // Fallbacks for old Communication sessions (before keys existed)
    if (gameId == GameIds.communication) {
      if (key == 'successfulResponses') {
        final score = metrics['score'];
        if (score is num) return score;
      }
      if (key == 'promptLevel') {
        // Old sessions didn't store prompts -> show 0 instead of —
        return 0;
      }
    }

    return null;
  }

  static Future<ParentOverviewSummary> loadWeeklySummary() async {
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) {
      return const ParentOverviewSummary(
        totalTimeSec7d: 0,
        favoriteGameTitle: null,
        droppedGameTitle: null,
        topImprovedGameTitle: null,
        topImprovedPercent: null,
        games: [],
      );
    }

    final now = DateTime.now();
    final start14d = now.subtract(const Duration(days: 14));
    final start7d = now.subtract(const Duration(days: 7));

    final snap = await FirebaseFirestore.instance
        .collection('children')
        .doc(childId)
        .collection('game_sessions')
        .where('startedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start14d))
        .orderBy('startedAt', descending: true)
        .get();

    final Map<String, List<Map<String, dynamic>>> recent = {};
    final Map<String, List<Map<String, dynamic>>> prev = {};

    for (final doc in snap.docs) {
      final d = doc.data();
      final gameId = (d['gameId'] ?? '').toString();
      if (gameId.isEmpty) continue;

      final ts = d['startedAt'] as Timestamp?;
      final startedAt = ts?.toDate();
      if (startedAt == null) continue;

      final bucket = startedAt.isAfter(start7d) ? recent : prev;
      (bucket[gameId] ??= []).add(d);
    }

    int totalTimeSec7d = 0;
    final List<ParentGameStats> gameStats = [];

    for (final entry in recent.entries) {
      final gameId = entry.key;
      final def = GameDefinitions.forId(gameId);
      final sessions7d = entry.value;

      final plays7d = sessions7d.length;
      int drops7d = 0;
      int timeSec7d = 0;

      final primaryVals = <double>[];
      final secondaryVals = <double>[];

      for (final s in sessions7d) {
        final completed = (s['completed'] == true);
        if (!completed) drops7d++;

        final dur = s['durationSec'];
        if (dur is num) timeSec7d += dur.toInt();

        final metrics = (s['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

        // ✅ FIX: use safe reader (supports old Communication sessions)
        final p = _readMetric(metrics, def.primaryMetricKey, gameId);
        if (p is num) primaryVals.add(p.toDouble());

        if (def.secondaryMetricKey != null) {
          final sec = _readMetric(metrics, def.secondaryMetricKey!, gameId);
          if (sec is num) secondaryVals.add(sec.toDouble());
        }
      }

      totalTimeSec7d += timeSec7d;

      final completionRate7d =
          plays7d == 0 ? 0.0 : (plays7d - drops7d) / plays7d;

      final primaryAvg7d = primaryVals.isEmpty
          ? null
          : primaryVals.reduce((a, b) => a + b) / primaryVals.length;

      final secondaryAvg7d = secondaryVals.isEmpty
          ? null
          : secondaryVals.reduce((a, b) => a + b) / secondaryVals.length;

      // improvement vs previous 7 days
      final prevSessions = prev[gameId] ?? [];
      final prevPrimaryVals = <double>[];
      for (final s in prevSessions) {
        final metrics = (s['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

        // ✅ FIX: same fallback for previous bucket too
        final p = _readMetric(metrics, def.primaryMetricKey, gameId);
        if (p is num) prevPrimaryVals.add(p.toDouble());
      }

      double? improvementPercent;
      if (primaryAvg7d != null && prevPrimaryVals.isNotEmpty) {
        final prevAvg =
            prevPrimaryVals.reduce((a, b) => a + b) / prevPrimaryVals.length;
        if (prevAvg != 0) {
          improvementPercent = def.primaryHigherIsBetter
              ? ((primaryAvg7d - prevAvg) / prevAvg) * 100.0
              : ((prevAvg - primaryAvg7d) / prevAvg) * 100.0;
        }
      }

      gameStats.add(
        ParentGameStats(
          gameId: gameId,
          title: def.title,
          plays7d: plays7d,
          drops7d: drops7d,
          totalTimeSec7d: timeSec7d,
          completionRate7d: completionRate7d,
          primaryAvg7d: primaryAvg7d,
          secondaryAvg7d: secondaryAvg7d,
          improvementPercent: improvementPercent,
        ),
      );
    }

    // favorite = max time (tie -> plays)
    ParentGameStats? favorite;
    for (final g in gameStats) {
      favorite ??= g;
      if (g.totalTimeSec7d > (favorite?.totalTimeSec7d ?? -1)) favorite = g;
      if (g.totalTimeSec7d == (favorite?.totalTimeSec7d ?? -1) &&
          g.plays7d > (favorite?.plays7d ?? -1)) {
        favorite = g;
      }
    }

    // dropped = highest dropRate (needs plays>=2)
    ParentGameStats? dropped;
    for (final g in gameStats) {
      if (g.plays7d < 2) continue;
      final rate = g.drops7d / g.plays7d;
      final best = dropped == null ? -1.0 : (dropped!.drops7d / dropped!.plays7d);
      if (rate > best) dropped = g;
    }

    // top improved
    ParentGameStats? topImproved;
    for (final g in gameStats) {
      final imp = g.improvementPercent;
      if (imp == null) continue;
      if (topImproved == null ||
          imp > (topImproved!.improvementPercent ?? -999999)) {
        topImproved = g;
      }
    }

    // sort list for display
    gameStats.sort((a, b) => b.totalTimeSec7d.compareTo(a.totalTimeSec7d));

    return ParentOverviewSummary(
      totalTimeSec7d: totalTimeSec7d,
      favoriteGameTitle: favorite?.title,
      droppedGameTitle: dropped?.title,
      topImprovedGameTitle: topImproved?.title,
      topImprovedPercent: topImproved?.improvementPercent,
      games: gameStats,
    );
  }
}
