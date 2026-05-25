import 'daily_log_model.dart';

enum ReadinessLevel { high, medium, low }

class ReadinessResult {
  final ReadinessLevel level;
  final String reason;

  ReadinessResult(this.level, this.reason);
}

class DailyReadinessService {
  static ReadinessResult compute(DailyLog log) {
    int score = 0;

    // ----- Sleep -----
    if (log.sleepHours != null) {
      if (log.sleepHours! >= 8) {
        score += 25;
      } else if (log.sleepHours! >= 6) {
        score += 15;
      } else {
        score += 5;
      }
    }

    if (log.sleepQuality != null) {
      if (log.sleepQuality == 'Good') score += 15;
      if (log.sleepQuality == 'Okay') score += 10;
      if (log.sleepQuality == 'Poor') score += 5;
    }

    if (log.napTaken == true) {
      score += 5;
    }

    // ----- Mood -----
    if (log.mood != null) {
      if (log.mood == 'Calm') score += 15;
      if (log.mood == 'Okay') score += 10;
      if (log.mood == 'Anxious' || log.mood == 'Overwhelmed') score += 5;
    }

    if (log.moodIntensity != null) {
      if (log.moodIntensity! >= 8) score -= 10;
      else if (log.moodIntensity! >= 5) score -= 5;
    }

    // ----- Meltdowns -----
    if (log.meltdownCount != null) {
      if (log.meltdownCount == '1') score -= 10;
      if (log.meltdownCount == '2') score -= 15;
      if (log.meltdownCount == '3+') score -= 20;
    }

    // ----- Environment -----
    if (log.routineChanged == true) {
      score -= 10;
    }

    if (log.triggers.isNotEmpty) {
      score -= log.triggers.length >= 3 ? 15 : 5;
    }

    // Clamp
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    // Decide readiness
    if (score >= 70) {
      return ReadinessResult(
        ReadinessLevel.high,
        'Good sleep and calm mood',
      );
    } else if (score >= 40) {
      return ReadinessResult(
        ReadinessLevel.medium,
        'Some stress detected',
      );
    } else {
      return ReadinessResult(
        ReadinessLevel.low,
        'Low energy or high stress',
      );
    }
  }
}
