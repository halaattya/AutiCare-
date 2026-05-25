import 'package:flutter/material.dart';
import '../../tracking/daily_log_model.dart';
import '../../ui/app_colors.dart';
import 'daily_log_screen.dart';
import '../../l10n/app_localizations.dart';

import '../../tracking/daily_readiness_service.dart';
import '../../tracking/parent_controls_service.dart';

class DailyLogSummaryScreen extends StatefulWidget {
  final DailyLog log;
  const DailyLogSummaryScreen({super.key, required this.log});

  @override
  State<DailyLogSummaryScreen> createState() => _DailyLogSummaryScreenState();
}

class _DailyLogSummaryScreenState extends State<DailyLogSummaryScreen> {
  bool _loadingPref = true;
  bool _keepRandom = false;

  @override
  void initState() {
    super.initState();
    _loadPref();
  }

  Future<void> _loadPref() async {
    final v = await ParentControlsService.getKeepRandomPlay();
    if (!mounted) return;
    setState(() {
      _keepRandom = v;
      _loadingPref = false;
    });
  }

  Future<void> _toggleKeepRandom() async {
    final newValue = !_keepRandom;
    setState(() => _keepRandom = newValue);
    await ParentControlsService.setKeepRandomPlay(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final log = widget.log;
    final dateText = log.dateId;

    String dash() => t.t('dash');
    String yn(bool x) => x ? t.t('yes') : t.t('no');

    String labelSleepQuality(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'Good':
          return t.t('sq_good');
        case 'Okay':
          return t.t('sq_okay');
        case 'Poor':
          return t.t('sq_poor');
        default:
          return v;
      }
    }

    String labelRoutineChange(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'School':
          return t.t('rc_school');
        case 'Travel':
          return t.t('rc_travel');
        case 'Guests':
          return t.t('rc_guests');
        case 'New place':
          return t.t('rc_new_place');
        case 'Other':
          return t.t('other');
        default:
          return v;
      }
    }

    String labelMood(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'Calm':
          return t.t('mood_calm');
        case 'Okay':
          return t.t('mood_okay');
        case 'Anxious':
          return t.t('mood_anxious');
        case 'Overwhelmed':
          return t.t('mood_overwhelmed');
        case 'Meltdown':
          return t.t('mood_meltdown');
        default:
          return v;
      }
    }

    String labelEffectiveness(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'Worked well':
          return t.t('eff_worked_well');
        case 'Worked a bit':
          return t.t('eff_worked_bit');
        case 'Didn’t help':
        case "Didn't help":
          return t.t('eff_didnt_help');
        default:
          return v;
      }
    }

    String labelSocial(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'None':
          return t.t('si_none');
        case 'Small':
          return t.t('si_small');
        case 'Good':
          return t.t('si_good');
        default:
          return v;
      }
    }

    String labelTherapy(String? v) {
      if (v == null) return dash();
      switch (v) {
        case 'Speech':
          return t.t('th_speech');
        case 'ABA':
          return t.t('th_aba');
        case 'OT':
          return t.t('th_ot');
        case 'Other':
          return t.t('other');
        default:
          return v;
      }
    }

    String labelBehavior(String v) {
      switch (v) {
        case 'Hyperactive':
          return t.t('bh_hyperactive');
        case 'Aggressive':
          return t.t('bh_aggressive');
        case 'Withdrawal':
          return t.t('bh_withdrawal');
        case 'Repetitive behavior':
          return t.t('bh_repetitive');
        case 'Sensory seeking':
          return t.t('bh_sens_seek');
        case 'Sensory avoidance':
          return t.t('bh_sens_avoid');
        case 'Good eye contact':
          return t.t('bh_eye_contact');
        case 'Good communication':
          return t.t('bh_good_comm');
        default:
          return v;
      }
    }

    String labelTrigger(String v) {
      switch (v) {
        case 'Loud sounds':
          return t.t('tr_loud');
        case 'Crowds':
          return t.t('tr_crowds');
        case 'Change in routine':
          return t.t('tr_change_routine');
        case 'Transitions':
          return t.t('tr_transitions');
        case 'Hunger':
          return t.t('tr_hunger');
        case 'Fatigue':
          return t.t('tr_fatigue');
        case 'New person':
          return t.t('tr_new_person');
        case 'Screen time':
          return t.t('tr_screen_time');
        case 'Touch / clothing':
          return t.t('tr_touch_clothes');
        case 'Other':
          return t.t('other');
        default:
          return v;
      }
    }

    String labelCalming(String v) {
      switch (v) {
        case 'Deep breathing':
          return t.t('cal_deep_breath');
        case 'Music':
          return t.t('cal_music');
        case 'Quiet space':
          return t.t('cal_quiet_space');
        case 'Weighted blanket':
          return t.t('cal_weighted_blanket');
        case 'Sensory toy':
          return t.t('cal_sensory_toy');
        case 'Walk / movement':
          return t.t('cal_walk');
        case 'Visual schedule':
          return t.t('cal_visual_schedule');
        case 'Hug / comfort':
          return t.t('cal_hug');
        case 'Snack / water':
          return t.t('cal_snack_water');
        case 'Other':
          return t.t('other');
        default:
          return v;
      }
    }

    String joinLabels(List<String> x, String Function(String) mapper) =>
        x.isEmpty ? dash() : x.map(mapper).join(', ');

    // ✅ Readiness computed from TODAY log (your mini-AI insight)
    final readiness = DailyReadinessService.compute(log);

    String readinessLabel() {
      switch (readiness.level) {
        case ReadinessLevel.low:
          return t.t('ready_low');
        case ReadinessLevel.medium:
          return t.t('ready_medium');
        case ReadinessLevel.high:
          return t.t('ready_high');
      }
    }

    String recommendedLabel() {
      // If parent chose random, recommendation becomes "random"
      if (_keepRandom) return t.t('ready_rec_random');

      switch (readiness.level) {
        case ReadinessLevel.low:
          return t.t('ready_rec_calm');
        case ReadinessLevel.medium:
          return t.t('ready_rec_familiar');
        case ReadinessLevel.high:
          return t.t('ready_rec_challenge');
      }
    }

    String noteText() {
      // Based on today's ... inferred ... recommending ...
      return '${t.t('ready_note_prefix')} '
          '${readinessLabel()} '
          '${t.t('ready_note_mid')} '
          '${recommendedLabel()}.';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: Text(
          t.t('daily_log_summary'),
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ NEW: Readiness widget at the top (looks like your screenshot style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.textDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('ready_title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        noteText(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSoft,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Button after sentence (your request)
                      _loadingPref
                          ? const SizedBox(height: 22, child: LinearProgressIndicator())
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _toggleKeepRandom,
                                icon: Icon(
                                  _keepRandom ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  color: AppColors.textDark,
                                ),
                                label: Text(
                                  _keepRandom ? t.t('ready_btn_random_on') : t.t('ready_btn_random_off'),
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textDark),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardPeach, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                const Icon(Icons.assignment_turned_in_rounded, color: AppColors.textDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t.t('daily_log_card_title')} $dateText',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _TableCard(rows: [
            _Row(t.t('day_rating'), log.dayRating == null ? dash() : '${log.dayRating} ★'),
            _Row(t.t('sleep'), log.sleepHours == null ? dash() : '${log.sleepHours}h'),
            _Row(t.t('sleep_quality_label'), labelSleepQuality(log.sleepQuality)),
            _Row(t.t('nap'), yn((log.napTaken ?? false))),
            _Row(t.t('routine_changed'), yn((log.routineChanged ?? false))),
            _Row(t.t('routine_change'), (log.routineChanged ?? false) ? labelRoutineChange(log.routineChangeType) : dash()),
            if (log.routineChangeType == 'Other') _Row(t.t('routine_other'), log.routineChangeOther ?? dash()),
          ]),

          const SizedBox(height: 12),
          _TableCard(rows: [
            _Row(t.t('mood'), labelMood(log.mood)),
            _Row(t.t('mood_intensity'), log.moodIntensity == null ? dash() : '${log.moodIntensity}/10'),
            _Row(t.t('meltdowns'), log.meltdownCount ?? dash()),
          ]),

          const SizedBox(height: 12),
          _TableCard(rows: [
            _Row(t.t('behaviors'), joinLabels(log.behaviors, labelBehavior)),
            _Row(t.t('triggers'), joinLabels(log.triggers, labelTrigger)),
            if (log.triggers.contains('Other')) _Row(t.t('trigger_other'), log.triggersOther ?? dash()),
            _Row(t.t('calming'), joinLabels(log.calmingStrategies, labelCalming)),
            if (log.calmingStrategies.contains('Other')) _Row(t.t('calming_other'), log.calmingOther ?? dash()),
            _Row(t.t('effectiveness_label'), labelEffectiveness(log.calmingEffectiveness)),
          ]),

          const SizedBox(height: 12),
          _TableCard(rows: [
            _Row(t.t('communication_practice'), yn((log.communicationPractice ?? false))),
            _Row(t.t('social_interaction'), labelSocial(log.socialInteraction)),
            _Row(t.t('therapy_today'), yn((log.therapyToday ?? false))),
            _Row(t.t('therapy_type_label'), (log.therapyToday ?? false) ? labelTherapy(log.therapyType) : dash()),
            if (log.therapyType == 'Other') _Row(t.t('therapy_other'), log.therapyOther ?? dash()),
          ]),

          const SizedBox(height: 12),
          _TableCard(rows: [
            _Row(t.t('focus_target_label'), log.focusTarget ?? dash()),
            if (log.focusTarget == 'Other') _Row(t.t('focus_other'), log.focusTargetOther ?? dash()),
            _Row(t.t('notes'), log.notes ?? dash()),
          ]),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyLogScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(t.t('edit'), style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row {
  final String k;
  final String v;
  _Row(this.k, this.v);
}

class _TableCard extends StatelessWidget {
  final List<_Row> rows;
  const _TableCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(r.k, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: Text(r.v, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textSoft)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
