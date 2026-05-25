import 'package:flutter/material.dart';

import '../../tracking/daily_log_model.dart';
import '../../tracking/daily_log_service.dart';
import '../../ui/app_colors.dart';
import 'daily_log_summary_screen.dart';
import '../../l10n/app_localizations.dart';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'daily_log_pdf_preview_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  DateTime _date = DateTime.now();
  bool _loading = true;

  // Info bar state
  bool _infoOpen = false;

  // form values
  int? dayRating;
  double? sleepHours;
  String? sleepQuality;
  bool napTaken = false;
  bool routineChanged = false;
  String? routineChangeType;
  String? routineChangeOther;

  String? mood;
  double moodIntensity = 5;
  String? meltdownCount;

  final Set<String> behaviors = {};
  final Set<String> triggers = {};
  String triggersOther = '';

  final Set<String> calming = {};
  String calmingOther = '';
  String? calmingEffectiveness;

  bool communicationPractice = false;
  String? socialInteraction;
  bool therapyToday = false;
  String? therapyType;
  String therapyOther = '';

  String? focusTarget;
  String focusTargetOther = '';

  final TextEditingController notesCtrl = TextEditingController();

  // Stored values (keep English in DB)
  static const behaviorsList = [
    'Hyperactive',
    'Aggressive',
    'Withdrawal',
    'Repetitive behavior',
    'Sensory seeking',
    'Sensory avoidance',
    'Good eye contact',
    'Good communication',
  ];

  static const triggersList = [
    'Loud sounds',
    'Crowds',
    'Change in routine',
    'Transitions',
    'Hunger',
    'Fatigue',
    'New person',
    'Screen time',
    'Touch / clothing',
  ];

  static const calmingList = [
    'Deep breathing',
    'Music',
    'Quiet space',
    'Weighted blanket',
    'Sensory toy',
    'Walk / movement',
    'Visual schedule',
    'Hug / comfort',
    'Snack / water',
  ];

  static const focusTargets = [
    'Follow instructions',
    'Reduce meltdowns',
    'Improve eye contact',
    'Improve transitions',
    'Use words instead of screaming',
    'Stay calm in public',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  // ===== Label mappers (display only) =====
  String _labelSleepQuality(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelRoutineChange(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelMood(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelEffectiveness(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelSocial(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelTherapy(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelBehavior(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelTrigger(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelCalming(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
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

  String _labelFocusTarget(BuildContext context, String v) {
    final t = AppLocalizations.of(context);
    switch (v) {
      case 'Follow instructions':
        return t.t('ft_follow');
      case 'Reduce meltdowns':
        return t.t('ft_reduce_meltdowns');
      case 'Improve eye contact':
        return t.t('ft_eye_contact');
      case 'Improve transitions':
        return t.t('ft_transitions');
      case 'Use words instead of screaming':
        return t.t('ft_words_not_screaming');
      case 'Stay calm in public':
        return t.t('ft_calm_public');
      case 'Other':
        return t.t('other');
      default:
        return v;
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final existing = await DailyLogService.getLogForDate(_date);
    if (existing != null) {
      dayRating = existing.dayRating;
      sleepHours = existing.sleepHours;
      sleepQuality = existing.sleepQuality;
      napTaken = existing.napTaken ?? false;
      routineChanged = existing.routineChanged ?? false;
      routineChangeType = existing.routineChangeType;
      routineChangeOther = existing.routineChangeOther;

      mood = existing.mood;
      moodIntensity = (existing.moodIntensity ?? 5).toDouble();
      meltdownCount = existing.meltdownCount;

      behaviors
        ..clear()
        ..addAll(existing.behaviors);
      triggers
        ..clear()
        ..addAll(existing.triggers);
      triggersOther = existing.triggersOther ?? '';

      calming
        ..clear()
        ..addAll(existing.calmingStrategies);
      calmingOther = existing.calmingOther ?? '';
      calmingEffectiveness = existing.calmingEffectiveness;

      communicationPractice = existing.communicationPractice ?? false;
      socialInteraction = existing.socialInteraction;
      therapyToday = existing.therapyToday ?? false;
      therapyType = existing.therapyType;
      therapyOther = existing.therapyOther ?? '';

      focusTarget = existing.focusTarget;
      focusTargetOther = existing.focusTargetOther ?? '';

      notesCtrl.text = existing.notes ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 2)),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _loadExisting();
  }

  Future<void> _saveAndShowSummary() async {
    final id = DailyLogService.dateIdFrom(_date);

    final log = DailyLog(
      dateId: id,
      date: _date,
      dayRating: dayRating,
      sleepHours: sleepHours,
      sleepQuality: sleepQuality,
      napTaken: napTaken,
      routineChanged: routineChanged,
      routineChangeType: routineChanged ? routineChangeType : null,
      routineChangeOther: routineChanged && routineChangeType == 'Other' ? routineChangeOther : null,
      mood: mood,
      moodIntensity: mood != null ? moodIntensity.round() : null,
      meltdownCount: meltdownCount,
      behaviors: behaviors.toList(),
      triggers: triggers.toList(),
      triggersOther: triggers.contains('Other') ? triggersOther : null,
      calmingStrategies: calming.toList(),
      calmingOther: calming.contains('Other') ? calmingOther : null,
      calmingEffectiveness: calmingEffectiveness,
      communicationPractice: communicationPractice,
      socialInteraction: socialInteraction,
      therapyToday: therapyToday,
      therapyType: therapyToday ? therapyType : null,
      therapyOther: therapyToday && therapyType == 'Other' ? therapyOther : null,
      focusTarget: focusTarget,
      focusTargetOther: focusTarget == 'Other' ? focusTargetOther : null,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    await DailyLogService.saveLog(log);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DailyLogSummaryScreen(log: log)),
    );
  }

  @override
  void dispose() {
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: Text(
          t.t('daily_log'),
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900),
        ),
        actions: [
  IconButton(
    onPressed: _pickDate,
    icon: const Icon(
      Icons.calendar_month_rounded,
      color: AppColors.textDark,
    ),
    tooltip: t.t('pick_date'),
  ),

  // ✅ PDF export button (NEW)
  IconButton(
    tooltip: t.locale.languageCode == 'ar'
        ? 'تصدير PDF'
        : 'Export PDF',
    icon: const Icon(
      Icons.picture_as_pdf_rounded,
      color: AppColors.textDark,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyLogPdfPreviewScreen(
            buildPdfBytes: () => _buildDailyLogPdf(t),
          ),
        ),
      );
    },
  ),
],

        
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
              children: [
                _dailyLogInfoBar(),
                const SizedBox(height: 12),

                _sectionTitle(t.t('day_snapshot')),
                _dateRow(),

                const SizedBox(height: 10),
                _ratingRow(),

                const SizedBox(height: 16),
                _sectionTitle(t.t('sleep_routine')),
                _numberField(
                  label: t.t('sleep_hours'),
                  hint: t.t('sleep_hours_hint'),
                  initial: sleepHours?.toString(),
                  onChanged: (v) => setState(() => sleepHours = double.tryParse(v)),
                ),
                const SizedBox(height: 10),
                _dropdown<String>(
                  label: t.t('sleep_quality'),
                  value: sleepQuality,
                  items: const ['Good', 'Okay', 'Poor'],
                  itemLabel: (v) => _labelSleepQuality(context, v),
                  onChanged: (v) => setState(() => sleepQuality = v),
                ),
                const SizedBox(height: 8),
                _switchTile(
                  title: t.t('nap_taken'),
                  value: napTaken,
                  onChanged: (v) => setState(() => napTaken = v),
                ),
                _switchTile(
                  title: t.t('routine_changed_today'),
                  value: routineChanged,
                  onChanged: (v) => setState(() => routineChanged = v),
                ),
                if (routineChanged) ...[
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    label: t.t('what_changed'),
                    value: routineChangeType,
                    items: const ['School', 'Travel', 'Guests', 'New place', 'Other'],
                    itemLabel: (v) => _labelRoutineChange(context, v),
                    onChanged: (v) => setState(() => routineChangeType = v),
                  ),
                  if (routineChangeType == 'Other')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _textField(
                        label: t.t('describe_change'),
                        hint: t.t('short_description'),
                        initial: routineChangeOther ?? '',
                        onChanged: (v) => setState(() => routineChangeOther = v),
                      ),
                    ),
                ],

                const SizedBox(height: 16),
                _sectionTitle(t.t('mood_emotional')),
                _dropdown<String>(
                  label: t.t('main_mood'),
                  value: mood,
                  items: const ['Calm', 'Okay', 'Anxious', 'Overwhelmed', 'Meltdown'],
                  itemLabel: (v) => _labelMood(context, v),
                  onChanged: (v) => setState(() => mood = v),
                ),
                const SizedBox(height: 10),
                _sliderCard(
                  title: t.t('mood_intensity_optional'),
                  subtitle: t.t('mood_intensity_subtitle'),
                  value: moodIntensity,
                  enabled: mood != null,
                  onChanged: (v) => setState(() => moodIntensity = v),
                ),
                const SizedBox(height: 10),
                _dropdown<String>(
                  label: t.t('meltdown_count'),
                  value: meltdownCount,
                  items: const ['0', '1', '2', '3+'],
                  itemLabel: (v) => v,
                  onChanged: (v) => setState(() => meltdownCount = v),
                ),

                const SizedBox(height: 16),
                _sectionTitle(t.t('behaviors_observed')),
                _chipMultiSelect(
                  options: behaviorsList,
                  selected: behaviors,
                  includeOther: false,
                  labelBuilder: (v) => _labelBehavior(context, v),
                ),

                const SizedBox(height: 16),
                _sectionTitle(t.t('triggers')),
                _chipMultiSelect(
                  options: triggersList,
                  selected: triggers,
                  includeOther: true,
                  otherLabel: 'Other',
                  labelBuilder: (v) => _labelTrigger(context, v),
                ),
                if (triggers.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _textField(
                      label: t.t('other_trigger'),
                      hint: t.t('write_trigger'),
                      initial: triggersOther,
                      onChanged: (v) => setState(() => triggersOther = v),
                    ),
                  ),

                const SizedBox(height: 16),
                _sectionTitle(t.t('calming_strategies')),
                _chipMultiSelect(
                  options: calmingList,
                  selected: calming,
                  includeOther: true,
                  otherLabel: 'Other',
                  labelBuilder: (v) => _labelCalming(context, v),
                ),
                if (calming.contains('Other'))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _textField(
                      label: t.t('other_calming_strategy'),
                      hint: t.t('write_what_helped'),
                      initial: calmingOther,
                      onChanged: (v) => setState(() => calmingOther = v),
                    ),
                  ),
                const SizedBox(height: 10),
                _dropdown<String>(
                  label: t.t('effectiveness'),
                  value: calmingEffectiveness,
                  items: const ['Worked well', 'Worked a bit', 'Didn’t help'],
                  itemLabel: (v) => _labelEffectiveness(context, v),
                  onChanged: (v) => setState(() => calmingEffectiveness = v),
                ),

                const SizedBox(height: 16),
                _sectionTitle(t.t('skills_therapy_optional')),
                _switchTile(
                  title: t.t('communication_practice_today'),
                  value: communicationPractice,
                  onChanged: (v) => setState(() => communicationPractice = v),
                ),
                const SizedBox(height: 8),
                _dropdown<String>(
                  label: t.t('social_interaction'),
                  value: socialInteraction,
                  items: const ['None', 'Small', 'Good'],
                  itemLabel: (v) => _labelSocial(context, v),
                  onChanged: (v) => setState(() => socialInteraction = v),
                ),
                const SizedBox(height: 8),
                _switchTile(
                  title: t.t('therapy_session_today'),
                  value: therapyToday,
                  onChanged: (v) => setState(() => therapyToday = v),
                ),
                if (therapyToday) ...[
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    label: t.t('therapy_type'),
                    value: therapyType,
                    items: const ['Speech', 'ABA', 'OT', 'Other'],
                    itemLabel: (v) => _labelTherapy(context, v),
                    onChanged: (v) => setState(() => therapyType = v),
                  ),
                  if (therapyType == 'Other')
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _textField(
                        label: t.t('other_therapy'),
                        hint: t.t('write_type'),
                        initial: therapyOther,
                        onChanged: (v) => setState(() => therapyOther = v),
                      ),
                    ),
                ],

                const SizedBox(height: 16),
                _sectionTitle(t.t('parent_focus_target_optional')),
                _dropdown<String>(
                  label: t.t('focus_target'),
                  value: focusTarget,
                  items: focusTargets,
                  itemLabel: (v) => _labelFocusTarget(context, v),
                  onChanged: (v) => setState(() => focusTarget = v),
                ),
                if (focusTarget == 'Other')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _textField(
                      label: t.t('write_focus_target'),
                      hint: t.t('short_goal'),
                      initial: focusTargetOther,
                      onChanged: (v) => setState(() => focusTargetOther = v),
                    ),
                  ),

                const SizedBox(height: 16),
                _sectionTitle(t.t('notes_optional')),
                _textArea(
                  controller: notesCtrl,
                  hint: t.t('notes_hint'),
                ),
              ],
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _saveAndShowSummary,
              child: Text(
                t.t('done_check'),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Info bar (embedded) ----------
  Widget _dailyLogInfoBar() {
    final t = AppLocalizations.of(context);

    Widget bullet(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  ', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardPeach,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: ExpansionTile(
            initiallyExpanded: _infoOpen,
            onExpansionChanged: (v) => setState(() => _infoOpen = v),
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: const Icon(Icons.info_outline, color: AppColors.textDark),
            title: Text(
              t.t('daily_log_info_title'),
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 14),
            ),
            children: [
              Text(
                t.t('dli_what_log_does'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              bullet(t.t('dli_b1')),
              bullet(t.t('dli_b2')),
              bullet(t.t('dli_b3')),

              const SizedBox(height: 12),
              Text(
                t.t('dli_how_to_use'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              bullet(t.t('dli_b4')),
              bullet(t.t('dli_b5')),
              bullet(t.t('dli_b6')),

              const SizedBox(height: 12),
              Text(
                t.t('dli_why_doctors'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              bullet(t.t('dli_b7')),
              bullet(t.t('dli_b8')),
              bullet(t.t('dli_b9')),

              const SizedBox(height: 12),
              Text(
                t.t('dli_privacy'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              bullet(t.t('dli_b10')),
              bullet(t.t('dli_b11')),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Small UI helpers ----------
  Widget _dateRow() {
    final t = AppLocalizations.of(context);
    final id = DailyLogService.dateIdFrom(_date);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.textDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${t.t('date')}: $id',
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            t.t('tap_calendar'),
            style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _ratingRow() {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.t('overall_day_rating_optional'),
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(5, (i) {
              final v = i + 1;
              final selected = dayRating == v;
              return ChoiceChip(
                label: Text('$v ★'),
                selected: selected,
                onSelected: (_) => setState(() => dayRating = selected ? null : v),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      );

  Widget _switchTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField({
    required String label,
    required String hint,
    String? initial,
    required ValueChanged<String> onChanged,
  }) {
    final ctrl = TextEditingController(text: initial ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, hintText: hint, border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }

  Widget _textField({
    required String label,
    required String hint,
    required String initial,
    required ValueChanged<String> onChanged,
  }) {
    final ctrl = TextEditingController(text: initial);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, hintText: hint, border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }

  Widget _textArea({required TextEditingController controller, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget _sliderCard({
    required String title,
    required String subtitle,
    required double value,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _chipMultiSelect({
    required List<String> options,
    required Set<String> selected,
    required bool includeOther,
    required String Function(String) labelBuilder,
    String otherLabel = 'Other',
  }) {
    final list = [...options];
    if (includeOther) list.add(otherLabel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardLight, borderRadius: BorderRadius.circular(18)),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: list.map((o) {
          final isSel = selected.contains(o);
          return FilterChip(
            label: Text(labelBuilder(o)),
            selected: isSel,
            onSelected: (_) => setState(() {
              if (isSel) {
                selected.remove(o);
              } else {
                selected.add(o);
              }
            }),
          );
        }).toList(),
      ),
    );
  }Future<Uint8List> _buildDailyLogPdf(AppLocalizations t) async {
  final isAr = t.locale.languageCode == 'ar';

  // ✅ Load Arabic-capable font (required to render Arabic in pdf correctly)
  final fontData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
  final arabicFont = pw.Font.ttf(fontData);

  final pdf = pw.Document();

  String fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

  String yesNo(bool v) => v ? t.t('yes') : t.t('no');

  // ✅ Convert stored English values into localized display labels
  String sleepQualityLabel(String? v) {
    if (v == null) return t.t('dash');
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

  String routineChangeLabel(String? v) {
    if (v == null) return t.t('dash');
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

  String moodLabel(String? v) {
    if (v == null) return t.t('dash');
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

  String effectivenessLabel(String? v) {
    if (v == null) return t.t('dash');
    switch (v) {
      case 'Worked well':
        return t.t('eff_worked_well');
      case 'Worked a bit':
        return t.t('eff_worked_bit');
      case "Didn't help":
      case 'Didn’t help':
        return t.t('eff_didnt_help');
      default:
        return v;
    }
  }

  String socialLabel(String? v) {
    if (v == null) return t.t('dash');
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

  String therapyLabel(String? v) {
    if (v == null) return t.t('dash');
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

  // Behaviors/Triggers/Calming are stored in English lists → map using your existing keys
  String behaviorLabel(String v) {
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

  String triggerLabel(String v) {
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

  String calmingLabel(String v) {
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

  String focusTargetLabel(String? v) {
    if (v == null) return t.t('dash');
    switch (v) {
      case 'Follow instructions':
        return t.t('ft_follow');
      case 'Reduce meltdowns':
        return t.t('ft_reduce_meltdowns');
      case 'Improve eye contact':
        return t.t('ft_eye_contact');
      case 'Improve transitions':
        return t.t('ft_transitions');
      case 'Use words instead of screaming':
        return t.t('ft_words_not_screaming');
      case 'Stay calm in public':
        return t.t('ft_calm_public');
      case 'Other':
        return t.t('other');
      default:
        return v;
    }
  }

  String listOrDashTranslated(Set<String> s, String Function(String) mapper) {
    if (s.isEmpty) return t.t('dash');
    return s.map(mapper).join(', ');
  }

  pw.Widget row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(width: 12),
          pw.Text(value),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      theme: pw.ThemeData.withFont(
        base: isAr ? arabicFont : null,
        bold: isAr ? arabicFont : null,
      ),
      build: (_) => [
        // ✅ RTL wrapper for Arabic
        pw.Directionality(
          textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                t.t('daily_log'),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('${t.t('date')}: ${fmtDate(_date)}'),
              pw.Divider(),

              pw.Text(
                t.t('daily_log_summary'),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),

              row(t.t('day_rating'), dayRating?.toString() ?? t.t('dash')),
              row(t.t('sleep_hours'), sleepHours?.toString() ?? t.t('dash')),
              row(t.t('sleep_quality_label'), sleepQualityLabel(sleepQuality)),
              row(t.t('nap'), yesNo(napTaken)),
              row(t.t('routine_changed'), yesNo(routineChanged)),
              if (routineChanged) row(t.t('routine_change'), routineChangeLabel(routineChangeType)),
              if (routineChanged && routineChangeType == 'Other')
                row(t.t('routine_other'), (routineChangeOther?.trim().isNotEmpty ?? false) ? routineChangeOther!.trim() : t.t('dash')),

              pw.SizedBox(height: 8),
              row(t.t('mood'), moodLabel(mood)),
              row(t.t('mood_intensity'), mood != null ? moodIntensity.round().toString() : t.t('dash')),
              row(t.t('meltdowns'), meltdownCount ?? t.t('dash')),

              pw.SizedBox(height: 8),
              row(t.t('behaviors'), listOrDashTranslated(behaviors, behaviorLabel)),
              row(t.t('triggers'), listOrDashTranslated(triggers, triggerLabel)),
              if (triggers.contains('Other') && triggersOther.trim().isNotEmpty)
                row(t.t('other_trigger'), triggersOther.trim()),

              pw.SizedBox(height: 8),
              row(t.t('calming'), listOrDashTranslated(calming, calmingLabel)),
              if (calming.contains('Other') && calmingOther.trim().isNotEmpty)
                row(t.t('other_calming_strategy'), calmingOther.trim()),
              row(t.t('effectiveness_label'), effectivenessLabel(calmingEffectiveness)),

              pw.SizedBox(height: 8),
              row(t.t('communication_practice'), yesNo(communicationPractice)),
              row(t.t('social_interaction'), socialLabel(socialInteraction)),
              row(t.t('therapy_today'), yesNo(therapyToday)),
              if (therapyToday) row(t.t('therapy_type_label'), therapyLabel(therapyType)),
              if (therapyToday && therapyType == 'Other' && therapyOther.trim().isNotEmpty)
                row(t.t('therapy_other'), therapyOther.trim()),

              pw.SizedBox(height: 8),
              row(t.t('focus_target_label'), focusTargetLabel(focusTarget)),
              if (focusTarget == 'Other' && focusTargetOther.trim().isNotEmpty)
                row(t.t('focus_other'), focusTargetOther.trim()),

              pw.SizedBox(height: 10),
              pw.Text(t.t('notes'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : t.t('dash')),
            ],
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

}


