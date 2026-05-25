import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../ui/app_colors.dart';
import '../../l10n/app_localizations.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _name = TextEditingController();
  DateTime? _dob;

  String? _communicationStageKey;
  String? _mainGoalAreaKey;
  String? _supportNeedsLevelKey;

  final Set<String> _sensoryKeys = {};
  final Set<String> _challengeKeys = {};
  final Set<String> _strengthKeys = {};

  // ✅ NEW (Step 1): placement helpers
  String? _attentionSpanKey; // how long the child can focus
  bool _canRead = true; // used later in Tap Target for non-readers

  bool _saving = false;
  String? _error;

  String _rand3() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(3, (_) => chars[r.nextInt(chars.length)]).join();
  }

  String _baseFromName(String name) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    final cleaned = first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return cleaned.isEmpty ? 'child' : cleaned.toLowerCase();
  }

  Future<String> _generateUniqueUsername(String childName) async {
    final base = _baseFromName(childName);

    for (int i = 0; i < 12; i++) {
      final candidate = '${base}_${_rand3()}';
      final key = candidate.toLowerCase();

      final q = await FirebaseFirestore.instance
          .collection('children')
          .where('usernameKey', isEqualTo: key)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return candidate;
    }

    return '${base}_${_rand3()}';
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 5, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now,
    );

    if (picked != null) setState(() => _dob = picked);
  }

  String _formatDob(AppLocalizations t) {
    if (_dob == null) return t.t('not_set');
    final d = _dob!;
    return '${d.day}.${d.month}.${d.year}';
  }

  int _calcAgeYears() {
    if (_dob == null) return -1;
    final now = DateTime.now();
    int age = now.year - _dob!.year;
    final hadBirthday = (now.month > _dob!.month) ||
        (now.month == _dob!.month && now.day >= _dob!.day);
    if (!hadBirthday) age--;
    return age;
  }

  int _supportToBaseLevel() {
    // support_1 = needs less support -> higher starting difficulty
    // support_3 = needs more support -> lower starting difficulty
    switch (_supportNeedsLevelKey) {
      case 'support_1':
        return 4;
      case 'support_2':
        return 3;
      case 'support_3':
        return 2;
      default:
        return 3;
    }
  }

  int _attentionToAdjustment() {
    // Higher span => can handle higher level
    switch (_attentionSpanKey) {
      case 'att_lt_1':
        return -2;
      case 'att_1_3':
        return -1;
      case 'att_3_5':
        return 0;
      case 'att_5_10':
        return 1;
      case 'att_10_plus':
        return 2;
      default:
        return 0;
    }
  }

  int _commToAdjustment() {
    // earlier communication => slightly easier start
    switch (_communicationStageKey) {
      case 'comm_preverbal':
        return -1;
      case 'comm_single_words':
        return -1;
      case 'comm_short_sentences':
        return 0;
      case 'comm_full_sentences':
        return 1;
      default:
        return 0;
    }
  }

  int _ageToAdjustment() {
    final age = _calcAgeYears();
    if (age < 0) return 0;
    if (age <= 3) return -1;
    if (age <= 5) return 0;
    if (age <= 8) return 1;
    return 2;
  }

  int _clampLevel(int v) => v.clamp(1, 5);

  Map<String, dynamic> _buildSensorySettings() {
    final loud = _sensoryKeys.contains('sens_loud_sounds');
    final bright = _sensoryKeys.contains('sens_bright_lights');
    final crowded = _sensoryKeys.contains('sens_crowded_places');

    return {
      // If loud sounds sensitivity -> default sound off
      'soundEnabledDefault': !loud,
      // If bright lights -> reduce motion to avoid overload + calmer visuals
      'reduceMotion': bright || crowded,
      // Optional: if you later implement contrast modes
      'highContrast': false,
    };
  }

  Map<String, dynamic> _buildPlacement() {
    
    int base = _supportToBaseLevel();
    base += _commToAdjustment();
    base += _attentionToAdjustment();
    base += _ageToAdjustment();

    
    if (_challengeKeys.contains('ch_attention_focus')) {
      base -= 1;
    }

    final appLevel = _clampLevel(base);

    final memoryStart = _clampLevel(appLevel + (_challengeKeys.contains('ch_attention_focus') ? -1 : 0)); 
    final matchStart = _clampLevel(appLevel);
    final tapStart = _clampLevel(appLevel + (_challengeKeys.contains('ch_attention_focus') ? -1 : 0));

    return {
      'appLevel': appLevel,
      // Keep keys simple for now; we will map them to your game_ids.dart in Step 2/3
      'startLevels': {
        'memory': memoryStart,
        'match': matchStart,
        'tap': tapStart,
      },
      // Current levels begin at start levels
      'currentLevels': {
        'memory': memoryStart,
        'match': matchStart,
        'tap': tapStart,
      },
      'sensorySettings': _buildSensorySettings(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = t.t('err_enter_child_name'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final username = await _generateUniqueUsername(name);
      final usernameKey = username.toLowerCase();

      final childRef = FirebaseFirestore.instance.collection('children').doc();

      final placement = _buildPlacement();

      await childRef.set({
        'name': name,
        'username': username,
        'usernameKey': usernameKey,

        'dateOfBirth': _dob == null ? null : Timestamp.fromDate(_dob!),

        // ✅ keys saved (same as your plan)
        'communicationStageKey': _communicationStageKey,
        'mainGoalAreaKey': _mainGoalAreaKey,
        'supportNeedsLevelKey': _supportNeedsLevelKey,

        'sensorySensitivityKeys': _sensoryKeys.toList(),
        'primaryChallengeKeys': _challengeKeys.toList(),
        'strengthKeys': _strengthKeys.toList(),

        // ✅ NEW: attention + reading
        'attentionSpanKey': _attentionSpanKey,
        'canRead': _canRead,

        // ✅ NEW: placement output (what the professor asked for)
        'placement': placement,

        'linkedAdults': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // set active child
      await FirebaseFirestore.instance.collection('parents').doc(user.uid).set(
        {'activeChildId': childRef.id},
        SetOptions(merge: true),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = t.t('err_failed_add_child'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _chipGroup({
    required AppLocalizations t,
    required List<String> keys,
    required Set<String> selected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: keys.map((k) {
        final on = selected.contains(k);
        return FilterChip(
          label: Text(t.t(k)),
          selected: on,
          onSelected: (v) {
            setState(() {
              if (v) {
                selected.add(k);
              } else {
                selected.remove(k);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    // Make sure these keys exist in your localization map
    final communicationOptions = <String>[
      'comm_preverbal',
      'comm_single_words',
      'comm_short_sentences',
      'comm_full_sentences',
    ];

    final goalOptions = <String>[
      'goal_communication',
      'goal_cognitive',
      'goal_attention',
      'goal_emotional',
    ];

    final supportOptions = <String>[
      'support_1',
      'support_2',
      'support_3',
    ];

    final sensoryOptions = <String>[
      'sens_bright_lights',
      'sens_loud_sounds',
      'sens_crowded_places',
      'sens_touch',
      'sens_no_strong',
    ];

    final challengeOptions = <String>[
      'ch_communication',
      'ch_attention_focus',
      'ch_social_interaction',
      'ch_emotional_regulation',
      'ch_motor_coordination',
    ];

    final strengthOptions = <String>[
      'st_patterns',
      'st_music',
      'st_visual_learning',
      'st_routine',
      'st_movement',
    ];

    // ✅ NEW: Attention span options
    final attentionOptions = <String>[
      'att_lt_1',
      'att_1_3',
      'att_3_5',
      'att_5_10',
      'att_10_plus',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          t.t('add_child_profile_title'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
              ],

              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: t.t('field_child_name_required'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              InkWell(
                onTap: _pickDob,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.textSoft),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${t.t('date_of_birth')}: ${_formatDob(t)}')),
                      Text(t.t('tap_to_select'),
                          style: const TextStyle(color: AppColors.textSoft)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Text(
                t.t('communication_stage'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              _drop(
                t,
                communicationOptions,
                _communicationStageKey,
                (v) => setState(() => _communicationStageKey = v),
              ),

              const SizedBox(height: 14),

              Text(
                t.t('main_goal_area'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              _drop(
                t,
                goalOptions,
                _mainGoalAreaKey,
                (v) => setState(() => _mainGoalAreaKey = v),
              ),

              const SizedBox(height: 14),

              Text(
                t.t('support_needs_level'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              _drop(
                t,
                supportOptions,
                _supportNeedsLevelKey,
                (v) => setState(() => _supportNeedsLevelKey = v),
              ),

              // ✅ NEW: Attention span
              const SizedBox(height: 14),
              Text(
                t.t('attention_span'),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              _drop(
                t,
                attentionOptions,
                _attentionSpanKey,
                (v) => setState(() => _attentionSpanKey = v),
              ),

              // ✅ NEW: Can read (same card style)
              const SizedBox(height: 14),
              Text(
                t.t('can_read_question'),
                style: understood,

              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _canRead ? t.t('yes') : t.t('no'),
                        style: const TextStyle(color: AppColors.textDark),
                      ),
                    ),
                    Switch(
                      value: _canRead,
                      activeColor: AppColors.accentBlue,
                      onChanged: (v) => setState(() => _canRead = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Text(
                t.t('sensory_sensitivities'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              _chipGroup(t: t, keys: sensoryOptions, selected: _sensoryKeys),

              const SizedBox(height: 14),
              Text(
                t.t('primary_challenges'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              _chipGroup(t: t, keys: challengeOptions, selected: _challengeKeys),

              const SizedBox(height: 14),
              Text(
                t.t('strengths_interests'),
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
              ),
              _chipGroup(t: t, keys: strengthOptions, selected: _strengthKeys),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          t.t('btn_save_child_profile'),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const TextStyle understood = TextStyle(
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
  );

  Widget _drop(
    AppLocalizations t,
    List<String> keys,
    String? value,
    void Function(String?) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(t.t('choose_one')),
          items: keys
              .map((k) => DropdownMenuItem<String>(
                    value: k,
                    child: Text(t.t(k)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
