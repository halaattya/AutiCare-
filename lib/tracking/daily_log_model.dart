import '../../l10n/app_localizations.dart';
class DailyLog {
  final String dateId; // yyyy-MM-dd
  final DateTime date;

  final int? dayRating; // 1..5
  final double? sleepHours;
  final String? sleepQuality; // Good/Okay/Poor
  final bool? napTaken;
  final bool? routineChanged;
  final String? routineChangeType; // School/Travel/Guests/New place/Other
  final String? routineChangeOther;

  final String? mood; // Calm/Okay/Anxious/Overwhelmed/Meltdown
  final int? moodIntensity; // 1..10
  final String? meltdownCount; // 0/1/2/3+

  final List<String> behaviors;
  final List<String> triggers;
  final String? triggersOther;

  final List<String> calmingStrategies;
  final String? calmingOther;
  final String? calmingEffectiveness; // Worked well/Worked a bit/Didn’t help

  final bool? communicationPractice;
  final String? socialInteraction; // None/Small/Good
  final bool? therapyToday;
  final String? therapyType; // Speech/ABA/OT/Other
  final String? therapyOther;

  final String? focusTarget; // dropdown or other
  final String? focusTargetOther;

  final String? notes;

  DailyLog({
    required this.dateId,
    required this.date,
    this.dayRating,
    this.sleepHours,
    this.sleepQuality,
    this.napTaken,
    this.routineChanged,
    this.routineChangeType,
    this.routineChangeOther,
    this.mood,
    this.moodIntensity,
    this.meltdownCount,
    this.behaviors = const [],
    this.triggers = const [],
    this.triggersOther,
    this.calmingStrategies = const [],
    this.calmingOther,
    this.calmingEffectiveness,
    this.communicationPractice,
    this.socialInteraction,
    this.therapyToday,
    this.therapyType,
    this.therapyOther,
    this.focusTarget,
    this.focusTargetOther,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateId': dateId,
      'date': date.toIso8601String(),
      'dayRating': dayRating,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'napTaken': napTaken,
      'routineChanged': routineChanged,
      'routineChangeType': routineChangeType,
      'routineChangeOther': routineChangeOther,
      'mood': mood,
      'moodIntensity': moodIntensity,
      'meltdownCount': meltdownCount,
      'behaviors': behaviors,
      'triggers': triggers,
      'triggersOther': triggersOther,
      'calmingStrategies': calmingStrategies,
      'calmingOther': calmingOther,
      'calmingEffectiveness': calmingEffectiveness,
      'communicationPractice': communicationPractice,
      'socialInteraction': socialInteraction,
      'therapyToday': therapyToday,
      'therapyType': therapyType,
      'therapyOther': therapyOther,
      'focusTarget': focusTarget,
      'focusTargetOther': focusTargetOther,
      'notes': notes,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static DailyLog fromMap(Map<String, dynamic> m) {
    DateTime parseDate(dynamic v) {
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return DailyLog(
      dateId: (m['dateId'] ?? '').toString(),
      date: parseDate(m['date']),
      dayRating: (m['dayRating'] is num) ? (m['dayRating'] as num).toInt() : null,
      sleepHours: (m['sleepHours'] is num) ? (m['sleepHours'] as num).toDouble() : null,
      sleepQuality: m['sleepQuality']?.toString(),
      napTaken: m['napTaken'] as bool?,
      routineChanged: m['routineChanged'] as bool?,
      routineChangeType: m['routineChangeType']?.toString(),
      routineChangeOther: m['routineChangeOther']?.toString(),
      mood: m['mood']?.toString(),
      moodIntensity: (m['moodIntensity'] is num) ? (m['moodIntensity'] as num).toInt() : null,
      meltdownCount: m['meltdownCount']?.toString(),
      behaviors: (m['behaviors'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      triggers: (m['triggers'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      triggersOther: m['triggersOther']?.toString(),
      calmingStrategies: (m['calmingStrategies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      calmingOther: m['calmingOther']?.toString(),
      calmingEffectiveness: m['calmingEffectiveness']?.toString(),
      communicationPractice: m['communicationPractice'] as bool?,
      socialInteraction: m['socialInteraction']?.toString(),
      therapyToday: m['therapyToday'] as bool?,
      therapyType: m['therapyType']?.toString(),
      therapyOther: m['therapyOther']?.toString(),
      focusTarget: m['focusTarget']?.toString(),
      focusTargetOther: m['focusTargetOther']?.toString(),
      notes: m['notes']?.toString(),
    );
  }
}
