import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/app_colors.dart';

class ParentChildProfileScreen extends StatefulWidget {
  final String childId;
  const ParentChildProfileScreen({super.key, required this.childId});

  @override
  State<ParentChildProfileScreen> createState() =>
      _ParentChildProfileScreenState();
}

class _ParentChildProfileScreenState extends State<ParentChildProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  DateTime? _dob;

  String? _communicationStageKey;
  String? _mainGoalAreaKey;
  String? _supportNeedsLevelKey;
  String? _attentionSpanKey;

  bool _canRead = false;

  final Set<String> _sensoryKeys = {};
  final Set<String> _challengeKeys = {};
  final Set<String> _strengthKeys = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _childRef =>
      FirebaseFirestore.instance.collection('children').doc(widget.childId);

  String _fmtDob(AppLocalizations t) {
    if (_dob == null) return t.t('not_set');
    final d = _dob!;
    return '${d.day}.${d.month}.${d.year}';
  }

  int _calcAgeYears(DateTime? dob) {
    if (dob == null) return -1;
    final now = DateTime.now();
    int age = now.year - dob.year;
    final hadBirthday =
        (now.month > dob.month) || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age--;
    return age;
  }

  Future<void> _pickDob(AppLocalizations t) async {
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

  void _enterEdit(Map<String, dynamic> data) {
    _nameCtrl.text = (data['name'] ?? '').toString();

    final ts = data['dateOfBirth'];
    if (ts is Timestamp) {
      _dob = ts.toDate();
    } else {
      _dob = null;
    }

    _communicationStageKey = data['communicationStageKey']?.toString();
    _mainGoalAreaKey = data['mainGoalAreaKey']?.toString();
    _supportNeedsLevelKey = data['supportNeedsLevelKey']?.toString();
    _attentionSpanKey = data['attentionSpanKey']?.toString();

    _canRead = (data['canRead'] == true);

    _sensoryKeys
      ..clear()
      ..addAll(((data['sensorySensitivityKeys'] as List?) ?? const [])
          .map((e) => e.toString()));

    _challengeKeys
      ..clear()
      ..addAll(((data['primaryChallengeKeys'] as List?) ?? const [])
          .map((e) => e.toString()));

    _strengthKeys
      ..clear()
      ..addAll(((data['strengthKeys'] as List?) ?? const [])
          .map((e) => e.toString()));

    setState(() => _editing = true);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  Future<void> _saveEdits(AppLocalizations t) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.locale.languageCode == 'ar' ? 'اكتبي الاسم' : 'Please enter a name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _childRef.set({
        'name': name,
        'dateOfBirth': _dob == null ? null : Timestamp.fromDate(_dob!),

        'communicationStageKey': _communicationStageKey,
        'mainGoalAreaKey': _mainGoalAreaKey,
        'supportNeedsLevelKey': _supportNeedsLevelKey,

        'attentionSpanKey': _attentionSpanKey,
        'canRead': _canRead,

        'sensorySensitivityKeys': _sensoryKeys.toList(),
        'primaryChallengeKeys': _challengeKeys.toList(),
        'strengthKeys': _strengthKeys.toList(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.locale.languageCode == 'ar' ? 'تم الحفظ ✅' : 'Saved ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.locale.languageCode == 'ar' ? 'خطأ:' : 'Error:'} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _infoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipGroup({
    required AppLocalizations t,
    required String title,
    required List<String> options,
    required Set<String> selected,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((k) {
            final isOn = selected.contains(k);
            return FilterChip(
              label: Text(t.t(k)),
              selected: isOn,
              onSelected: enabled
                  ? (v) {
                      setState(() {
                        if (v) {
                          selected.add(k);
                        } else {
                          selected.remove(k);
                        }
                      });
                    }
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  // ================= Parent Controls Helpers (NEW) =================

  int _clampLevel(dynamic v, {int fallback = 1}) {
    final n = (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
    if (n < 1) return 1;
    if (n > 5) return 5;
    return n;
  }

  Future<void> _setGameLevel(String gameKey, int newLevel) async {
    final lvl = newLevel.clamp(1, 5);

    // Save override + update visible current level immediately
    await _childRef.set({
      'parentControls': {
        'levelOverride': {gameKey: lvl}
      },
      'placement': {
        'currentLevels': {gameKey: lvl}
      },
    }, SetOptions(merge: true));
  }

  Future<void> _toggleLock(String gameKey, bool value) async {
    await _childRef.set({
      'parentControls': {
        'lockLevel': {gameKey: value}
      }
    }, SetOptions(merge: true));
  }

  Future<void> _toggleHide(String gameKey, bool value) async {
    await _childRef.set({
      'parentControls': {
        'hiddenGames': {gameKey: value}
      }
    }, SetOptions(merge: true));
  }

  Widget _gameControlRow({
    required bool isAr,
    required String label,
    required String gameKey,
    required int level,
    required bool locked,
    required bool hidden,
  }) {
    final disabledColor = AppColors.textSoft.withOpacity(0.5);
    final textColor = hidden ? disabledColor : AppColors.textDark;

    return Opacity(
      opacity: hidden ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),

            // 👁 Hide / Show
            IconButton(
              tooltip: hidden
                  ? (isAr ? 'إظهار اللعبة للطفل' : 'Show game to child')
                  : (isAr ? 'إخفاء اللعبة عن الطفل' : 'Hide game from child'),
              icon: Icon(
                hidden ? Icons.visibility_off : Icons.visibility,
                color: hidden ? disabledColor : AppColors.textSoft,
              ),
              onPressed: () => _toggleHide(gameKey, !hidden),
            ),

            // − level
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: hidden ? disabledColor : null,
              onPressed: (!hidden && level > 1)
                  ? () => _setGameLevel(gameKey, level - 1)
                  : null,
            ),

            Text(
              level.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: textColor,
              ),
            ),

            // + level
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: hidden ? disabledColor : null,
              onPressed: (!hidden && level < 5)
                  ? () => _setGameLevel(gameKey, level + 1)
                  : null,
            ),

            // 🔒 Lock
            IconButton(
              tooltip: isAr ? 'قفل المستوى' : 'Lock level',
              icon: Icon(
                locked ? Icons.lock : Icons.lock_open,
                color: locked ? AppColors.textDark : AppColors.textSoft,
              ),
              onPressed: hidden ? null : () => _toggleLock(gameKey, !locked),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Delete Child (NEW) =================

  Future<void> _confirmDeleteChild(AppLocalizations t) async {
    final isAr = t.locale.languageCode == 'ar';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تأكيد الحذف' : 'Confirm deletion'),
        content: Text(
          isAr
              ? 'هل أنتِ متأكدة أنك تريدين حذف هذا الطفل؟ سيتم حذف بياناته نهائيًا.'
              : 'Are you sure you want to delete this child? This will permanently remove their data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteChild(t);
    }
  }

  Future<void> _deleteChild(AppLocalizations t) async {
    final isAr = t.locale.languageCode == 'ar';

    setState(() => _saving = true);
    try {
      // If this child is active for the parent, clear it.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final parentRef =
            FirebaseFirestore.instance.collection('parents').doc(uid);

        final parentSnap = await parentRef.get();
        final parentData = parentSnap.data() as Map<String, dynamic>?;
        final activeChildId = parentData?['activeChildId']?.toString();

        if (activeChildId == widget.childId) {
          await parentRef.set({'activeChildId': null}, SetOptions(merge: true));
        }
      }

      // Delete child document
      await _childRef.delete();

      if (mounted) {
        Navigator.pop(context); // go back to parent dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم حذف الطفل ✅' : 'Child deleted ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isAr ? 'خطأ:' : 'Error:'} $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isAr = t.locale.languageCode == 'ar';

    // Same option keys as AddChildScreen (so labels match your localization)
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
      'sens_food_textures',
      'sens_smells',
    ];

    final challengeOptions = <String>[
      'ch_attention_focus',
      'ch_emotional_regulation',
      'ch_transition_change',
      'ch_social_interaction',
      'ch_sensory_overload',
      'ch_motor_coordination',
    ];

    final strengthOptions = <String>[
      'st_patterns',
      'st_music',
      'st_visual_learning',
      'st_routine',
      'st_movement',
    ];

    final attentionOptions = <String>[
      'att_lt_1',
      'att_1_3',
      'att_3_5',
      'att_5_10',
      'att_10_plus',
    ];

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _childRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data?.data();
        if (data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.cardPeach,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textDark),
              title: Text(
                isAr ? 'ملف الطفل' : 'Child Profile',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            body: Center(
              child: Text(isAr ? 'البيانات غير موجودة' : 'No data found'),
            ),
          );
        }

        final name = (data['name'] ?? 'Child').toString();
        final username = (data['username'] ?? '').toString();

        final placement = (data['placement'] as Map?)?.cast<String, dynamic>();
        final startLevels =
            (placement?['startLevels'] as Map?)?.cast<String, dynamic>() ?? {};
        final currentLevels =
            (placement?['currentLevels'] as Map?)?.cast<String, dynamic>() ?? {};

        // Parent controls (NEW)
        final pc = (data['parentControls'] as Map?)?.cast<String, dynamic>() ?? {};
        final hiddenGames =
            (pc['hiddenGames'] as Map?)?.cast<String, dynamic>() ?? {};
        final lockLevel =
            (pc['lockLevel'] as Map?)?.cast<String, dynamic>() ?? {};
        final levelOverride =
            (pc['levelOverride'] as Map?)?.cast<String, dynamic>() ?? {};

        // Prefer currentLevels, else startLevels, else 1
        int mem = _clampLevel(currentLevels['memory'] ?? startLevels['memory'] ?? 1);
        int match = _clampLevel(currentLevels['match'] ?? startLevels['match'] ?? 1);
        int tap = _clampLevel(currentLevels['tap'] ?? startLevels['tap'] ?? 1);

        // ✅ ADDED: communication levels (key = comm)
        int comm = _clampLevel(currentLevels['comm'] ?? startLevels['comm'] ?? 1);

        // If parent override exists, reflect it (optional but helps consistency)
        if (levelOverride.containsKey('memory')) mem = _clampLevel(levelOverride['memory'], fallback: mem);
        if (levelOverride.containsKey('match')) match = _clampLevel(levelOverride['match'], fallback: match);
        if (levelOverride.containsKey('tap')) tap = _clampLevel(levelOverride['tap'], fallback: tap);

        // ✅ ADDED: reflect override for communication too
        if (levelOverride.containsKey('comm')) comm = _clampLevel(levelOverride['comm'], fallback: comm);

        final appLevel = (placement?['appLevel'] ?? 1);

        final dobTs = data['dateOfBirth'];
        DateTime? dob;
        if (dobTs is Timestamp) dob = dobTs.toDate();
        final age = _calcAgeYears(dob);

        final memHidden = hiddenGames['memory'] == true;
        final matchHidden = hiddenGames['match'] == true;
        final tapHidden = hiddenGames['tap'] == true;

        // ✅ ADDED: communication hide
        final commHidden = hiddenGames['comm'] == true;

        final memLocked = lockLevel['memory'] == true;
        final matchLocked = lockLevel['match'] == true;
        final tapLocked = lockLevel['tap'] == true;

        // ✅ ADDED: communication lock
        final commLocked = lockLevel['comm'] == true;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.cardPeach,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textDark),
            title: Text(
              isAr ? 'ملف الطفل' : 'Child Profile',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            actions: [
              IconButton(
                tooltip: isAr ? 'حذف الطفل' : 'Delete child',
                icon: const Icon(Icons.delete_outline, color: AppColors.textDark),
                onPressed: _saving ? null : () => _confirmDeleteChild(t),
              ),
              if (!_editing)
                IconButton(
                  tooltip: isAr ? 'تعديل' : 'Edit',
                  icon: const Icon(Icons.edit, color: AppColors.textDark),
                  onPressed: () => _enterEdit(data),
                )
              else ...[
                IconButton(
                  tooltip: isAr ? 'إلغاء' : 'Cancel',
                  icon: const Icon(Icons.close, color: AppColors.textDark),
                  onPressed: _saving ? null : _cancelEdit,
                ),
                IconButton(
                  tooltip: isAr ? 'حفظ' : 'Save',
                  icon: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, color: AppColors.textDark),
                  onPressed: _saving ? null : () => _saveEdits(t),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBlue,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.child_care,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (username.isNotEmpty)
                                Text(
                                  isAr ? 'رمز الربط: $username' : 'Link code: $username',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSoft,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle(isAr ? 'المستويات الحالية' : 'Current Levels'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          label: isAr ? 'مستوى التطبيق' : 'App Level',
                          value: appLevel.toString(),
                        ),
                        const Divider(),

                        // ✅ NEW: game controls inside Current Levels card
                        _gameControlRow(
                          isAr: isAr,
                          label: isAr ? 'الذاكرة' : 'Memory',
                          gameKey: 'memory',
                          level: mem,
                          locked: memLocked,
                          hidden: memHidden,
                        ),
                        _gameControlRow(
                          isAr: isAr,
                          label: isAr ? 'المطابقة' : 'Shape Matching',
                          gameKey: 'match',
                          level: match,
                          locked: matchLocked,
                          hidden: matchHidden,
                        ),
                        _gameControlRow(
                          isAr: isAr,
                          label: isAr ? 'النقر على الهدف' : 'Tap Target',
                          gameKey: 'tap',
                          level: tap,
                          locked: tapLocked,
                          hidden: tapHidden,
                        ),

                        // ✅ ADDED: Communication game row
                        _gameControlRow(
                          isAr: isAr,
                          label: isAr ? 'تعابير الوجه' : 'Match Face Expression',
                          gameKey: 'comm',
                          level: comm,
                          locked: commLocked,
                          hidden: commHidden,
                        ),

                        const SizedBox(height: 6),
                        Text(
                          isAr
                              ? '⚡ يمكن للوالد تعديل المستوى، وإخفاء اللعبة، وقفل المستوى لمنع التغيير التلقائي.'
                              : '⚡ Parents can override levels, hide games, and lock levels to prevent auto changes.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle(isAr ? 'معلومات الطفل' : 'Child Information'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardLavender,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        if (!_editing) ...[
                          _infoRow(
                            label: isAr ? 'الاسم' : 'Name',
                            value: name,
                          ),
                          _infoRow(
                            label: isAr ? 'تاريخ الميلاد' : 'Date of birth',
                            value: dob == null
                                ? t.t('not_set')
                                : '${dob.day}.${dob.month}.${dob.year}',
                          ),
                          _infoRow(
                            label: isAr ? 'العمر' : 'Age',
                            value: age < 0 ? '—' : '${age.toString()}',
                          ),
                        ] else ...[
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الاسم' : 'Name',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _saving ? null : () => _pickDob(t),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: AppColors.textDark),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isAr
                                          ? 'تاريخ الميلاد: ${_fmtDob(t)}'
                                          : 'Date of birth: ${_fmtDob(t)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Dropdowns + canRead
                  _sectionTitle(isAr ? 'الخيارات' : 'Selections'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardPeach,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _drop(
                          enabled: _editing && !_saving,
                          label: isAr ? 'مرحلة التواصل' : 'Communication Stage',
                          value: _editing ? _communicationStageKey : data['communicationStageKey']?.toString(),
                          options: communicationOptions,
                          t: t,
                          onChanged: (v) => setState(() => _communicationStageKey = v),
                        ),
                        const SizedBox(height: 10),
                        _drop(
                          enabled: _editing && !_saving,
                          label: isAr ? 'الهدف الرئيسي' : 'Main Goal',
                          value: _editing ? _mainGoalAreaKey : data['mainGoalAreaKey']?.toString(),
                          options: goalOptions,
                          t: t,
                          onChanged: (v) => setState(() => _mainGoalAreaKey = v),
                        ),
                        const SizedBox(height: 10),
                        _drop(
                          enabled: _editing && !_saving,
                          label: isAr ? 'مستوى الدعم' : 'Support Needs',
                          value: _editing ? _supportNeedsLevelKey : data['supportNeedsLevelKey']?.toString(),
                          options: supportOptions,
                          t: t,
                          onChanged: (v) => setState(() => _supportNeedsLevelKey = v),
                        ),
                        const SizedBox(height: 10),
                        _drop(
                          enabled: _editing && !_saving,
                          label: isAr ? 'مدة الانتباه' : 'Attention Span',
                          value: _editing ? _attentionSpanKey : data['attentionSpanKey']?.toString(),
                          options: attentionOptions,
                          t: t,
                          onChanged: (v) => setState(() => _attentionSpanKey = v),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: _editing ? _canRead : (data['canRead'] == true),
                          onChanged: (_editing && !_saving)
                              ? (v) => setState(() => _canRead = v)
                              : null,
                          title: Text(isAr ? 'هل يستطيع القراءة؟' : 'Can read?'),
                        ),
                      ],
                    ),
                  ),

                  // Chips
                  _chipGroup(
                    t: t,
                    title: isAr ? 'الحساسية الحسية' : 'Sensory Sensitivities',
                    options: sensoryOptions,
                    selected: _editing ? _sensoryKeys : Set<String>.from(
                      ((data['sensorySensitivityKeys'] as List?) ?? const [])
                          .map((e) => e.toString()),
                    ),
                    enabled: _editing && !_saving,
                  ),
                  _chipGroup(
                    t: t,
                    title: isAr ? 'التحديات الأساسية' : 'Primary Challenges',
                    options: challengeOptions,
                    selected: _editing ? _challengeKeys : Set<String>.from(
                      ((data['primaryChallengeKeys'] as List?) ?? const [])
                          .map((e) => e.toString()),
                    ),
                    enabled: _editing && !_saving,
                  ),
                  _chipGroup(
                    t: t,
                    title: isAr ? 'نقاط القوة' : 'Strengths',
                    options: strengthOptions,
                    selected: _editing ? _strengthKeys : Set<String>.from(
                      ((data['strengthKeys'] as List?) ?? const [])
                          .map((e) => e.toString()),
                    ),
                    enabled: _editing && !_saving,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _drop({
    required bool enabled,
    required String label,
    required String? value,
    required List<String> options,
    required AppLocalizations t,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = (value != null && options.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      items: options
          .map((k) => DropdownMenuItem<String>(
                value: k,
                child: Text(t.t(k)),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
