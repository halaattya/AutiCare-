import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../ui/app_colors.dart';
import '../../tracking/active_child_provider.dart';
import '../../tracking/game_ids.dart';
import '../../tracking/game_session_service.dart';

class CommunicationGameScreen extends StatefulWidget {
  final String? childId;

  const CommunicationGameScreen({
    super.key,
    this.childId,
  });

  @override
  State<CommunicationGameScreen> createState() =>
      _CommunicationGameScreenState();
}

class _CommunicationGameScreenState extends State<CommunicationGameScreen> {
  final _rng = Random();

  // ================== LEVELS ==================
  int _levelPlayed = 1;
  bool _levelLoaded = false;

  // rounds per level (your exact rules)
  int totalRounds = 3;

  // gameplay state
  int round = 1;
  int score = 0;
  int mistakes = 0;

  bool _inputLocked = false;
  bool _sessionSaved = false;
  bool _didStartPlaying = false;

  DateTime? _questionStart;
  int _totalCorrectTimeMs = 0;

  late DateTime _startedAt;

  // Current question
  _Emotion? _targetEmotion;
  _Situation? _targetSituation; // only for level 5
  List<_Emotion> _options = [];

  // ✅ NEW: selection + feedback states
  _Emotion? _selected;
  bool _showFeedback = false;
  bool _lastWasCorrect = false;

  // TTS
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsBusy = false;

  // ================== DATA ==================

  // Level 1 emotions (3)
  static const List<_Emotion> _emotionsL1 = [
    _Emotion(
        id: 'happy',
        labelEn: 'Happy',
        labelAr: 'سعيد',
        asset: 'assets/communication/faces/happy.png'),
    _Emotion(
        id: 'okay',
        labelEn: 'Okay',
        labelAr: 'عادي',
        asset: 'assets/communication/faces/okay.png'),
    _Emotion(
        id: 'sad',
        labelEn: 'Sad',
        labelAr: 'حزين',
        asset: 'assets/communication/faces/sad.png'),
  ];

  // Level 2 emotions (5)
  static const List<_Emotion> _emotionsL2 = [
    _Emotion(
        id: 'happy',
        labelEn: 'Happy',
        labelAr: 'سعيد',
        asset: 'assets/communication/faces/happy.png'),
    _Emotion(
        id: 'sad',
        labelEn: 'Sad',
        labelAr: 'حزين',
        asset: 'assets/communication/faces/sad.png'),
    _Emotion(
        id: 'okay',
        labelEn: 'Okay',
        labelAr: 'عادي',
        asset: 'assets/communication/faces/okay.png'),
    _Emotion(
        id: 'excited',
        labelEn: 'Excited',
        labelAr: 'متحمس',
        asset: 'assets/communication/faces/excited.png'),
    _Emotion(
        id: 'angry',
        labelEn: 'Angry',
        labelAr: 'غاضب',
        asset: 'assets/communication/faces/angry.png'),
  ];

  // Level 3 emotions (8)
  static const List<_Emotion> _emotionsL3 = [
    _Emotion(
        id: 'happy',
        labelEn: 'Happy',
        labelAr: 'سعيد',
        asset: 'assets/communication/faces/happy.png'),
    _Emotion(
        id: 'sad',
        labelEn: 'Sad',
        labelAr: 'حزين',
        asset: 'assets/communication/faces/sad.png'),
    _Emotion(
        id: 'okay',
        labelEn: 'Okay',
        labelAr: 'عادي',
        asset: 'assets/communication/faces/okay.png'),
    _Emotion(
        id: 'excited',
        labelEn: 'Excited',
        labelAr: 'متحمس',
        asset: 'assets/communication/faces/excited.png'),
    _Emotion(
        id: 'angry',
        labelEn: 'Angry',
        labelAr: 'غاضب',
        asset: 'assets/communication/faces/angry.png'),
    _Emotion(
        id: 'scared',
        labelEn: 'Scared',
        labelAr: 'خائف',
        asset: 'assets/communication/faces/scared.png'),
    _Emotion(
        id: 'surprised',
        labelEn: 'Surprised',
        labelAr: 'متفاجئ',
        asset: 'assets/communication/faces/surprised.png'),
    _Emotion(
        id: 'tired',
        labelEn: 'Tired',
        labelAr: 'متعب',
        asset: 'assets/communication/faces/tired.png'),
  ];

  // Level 4 emotions (many = 12)
  static const List<_Emotion> _emotionsL4 = [
    // same 8
    _Emotion(
        id: 'happy',
        labelEn: 'Happy',
        labelAr: 'سعيد',
        asset: 'assets/communication/faces/happy.png'),
    _Emotion(
        id: 'sad',
        labelEn: 'Sad',
        labelAr: 'حزين',
        asset: 'assets/communication/faces/sad.png'),
    _Emotion(
        id: 'okay',
        labelEn: 'Okay',
        labelAr: 'عادي',
        asset: 'assets/communication/faces/okay.png'),
    _Emotion(
        id: 'excited',
        labelEn: 'Excited',
        labelAr: 'متحمس',
        asset: 'assets/communication/faces/excited.png'),
    _Emotion(
        id: 'angry',
        labelEn: 'Angry',
        labelAr: 'غاضب',
        asset: 'assets/communication/faces/angry.png'),
    _Emotion(
        id: 'scared',
        labelEn: 'Scared',
        labelAr: 'خائف',
        asset: 'assets/communication/faces/scared.png'),
    _Emotion(
        id: 'surprised',
        labelEn: 'Surprised',
        labelAr: 'متفاجئ',
        asset: 'assets/communication/faces/surprised.png'),
    _Emotion(
        id: 'tired',
        labelEn: 'Tired',
        labelAr: 'متعب',
        asset: 'assets/communication/faces/tired.png'),

    // + 4 more
    _Emotion(
        id: 'confused',
        labelEn: 'Confused',
        labelAr: 'محتار',
        asset: 'assets/communication/faces/confused.png'),
    _Emotion(
        id: 'disappointed',
        labelEn: 'Disappointed',
        labelAr: 'محبط',
        asset: 'assets/communication/faces/disappointed.png'),
    _Emotion(
        id: 'calm',
        labelEn: 'Calm',
        labelAr: 'هادئ',
        asset: 'assets/communication/faces/calm.png'),
    _Emotion(
        id: 'worried',
        labelEn: 'Worried',
        labelAr: 'قلق',
        asset: 'assets/communication/faces/worried.png'),
  ];

  // Level 5 situations (image + text) (at least 10)
  // Uses Level 4 emotions as answer set.
  static const List<_Situation> _situationsL5 = [
    _Situation(
      id: 'new_toy',
      textEn: 'The child got a new toy.',
      textAr: 'الطفل حصل على لعبة جديدة.',
      asset: 'assets/communication/situations/s01_new_toy.png',
      correctEmotionId: 'happy',
    ),
    _Situation(
      id: 'dropped_icecream',
      textEn: 'The child dropped their ice cream.',
      textAr: 'الطفل أسقط الآيس كريم.',
      asset: 'assets/communication/situations/s02_dropped_icecream.png',
      correctEmotionId: 'sad',
    ),
    _Situation(
      id: 'loud_noise',
      textEn: 'There is a loud noise in the room.',
      textAr: 'هناك صوت عالي في الغرفة.',
      asset: 'assets/communication/situations/s03_loud_noise.png',
      correctEmotionId: 'scared',
    ),
    _Situation(
      id: 'waiting_long',
      textEn: 'The child is waiting for a long time.',
      textAr: 'الطفل ينتظر لفترة طويلة.',
      asset: 'assets/communication/situations/s04_waiting_long.png',
      correctEmotionId: 'worried',
    ),
    _Situation(
      id: 'friend_no_play',
      textEn: 'A friend does not want to play.',
      textAr: 'صديق لا يريد اللعب.',
      asset: 'assets/communication/situations/s05_friend_no_play.png',
      correctEmotionId: 'disappointed',
    ),
    _Situation(
      id: 'birthday_surprise',
      textEn: 'A surprise at a birthday party!',
      textAr: 'مفاجأة في حفلة عيد ميلاد!',
      asset: 'assets/communication/situations/s06_birthday_surprise.png',
      correctEmotionId: 'surprised',
    ),
    _Situation(
      id: 'favorite_game',
      textEn: 'The child is playing a favorite game.',
      textAr: 'الطفل يلعب لعبته المفضلة.',
      asset: 'assets/communication/situations/s07_favorite_game.png',
      correctEmotionId: 'excited',
    ),
    _Situation(
      id: 'too_many_activities',
      textEn: 'Too many activities in one day.',
      textAr: 'الكثير من الأنشطة في يوم واحد.',
      asset: 'assets/communication/situations/s08_too_many_activities.png',
      correctEmotionId: 'tired',
    ),
    _Situation(
      id: 'unclear_instructions',
      textEn: 'The instructions are not clear.',
      textAr: 'التعليمات غير واضحة.',
      asset: 'assets/communication/situations/s09_unclear_instructions.png',
      correctEmotionId: 'confused',
    ),
    _Situation(
      id: 'soft_music',
      textEn: 'Sitting quietly with soft music.',
      textAr: 'الجلوس بهدوء مع موسيقى هادئة.',
      asset: 'assets/communication/situations/s10_soft_music.png',
      correctEmotionId: 'calm',
    ),
  ];

  // ================== LIFECYCLE ==================

  @override
  void initState() {
    super.initState();
    _startSession();

    Future.microtask(() async {
      await _initTts();
      await _loadLevelFromFirebase();
      if (!mounted) return;
      _startGame();
    });
  }

  @override
  void dispose() {
    // Save incomplete if user exits mid-game
    if (_didStartPlaying && !_sessionSaved) {
      _saveSession(completed: false);
    }
    _tts.stop();
    super.dispose();
  }

  // ================== TTS ==================

  Future<void> _initTts() async {
    try {
      final locale = Localizations.localeOf(context);
      final lang = locale.languageCode == 'ar' ? 'ar-SA' : 'en-US';

      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _ttsReady = true;
    } catch (_) {
      // If TTS fails, game still works (silent)
      _ttsReady = false;
    }
  }

  // ✅ We disable auto audio because it can reveal the correct answer.
  bool get _audioAuto => false;

  // ✅ Now all levels use tap-to-speak
  bool get _audioOnTap => true;

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    if (_ttsBusy) return;
    _ttsBusy = true;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // ignore
    } finally {
      _ttsBusy = false;
    }
  }

  String _emotionLabel(_Emotion e) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? e.labelAr : e.labelEn;
  }

  String _situationText(_Situation s) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? s.textAr : s.textEn;
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  // ================== LEVEL LOAD ==================

  Future<void> _loadLevelFromFirebase() async {
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) {
      setState(() => _levelLoaded = true);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('children')
        .doc(childId)
        .get();
    final data = doc.data();
    if (data == null) {
      setState(() => _levelLoaded = true);
      return;
    }

    final placement = (data['placement'] as Map?)?.cast<String, dynamic>();
    final currentLevels =
        (placement?['currentLevels'] as Map?)?.cast<String, dynamic>();
    final startLevels =
        (placement?['startLevels'] as Map?)?.cast<String, dynamic>();

    int level = 1;
    final cur = currentLevels?['comm'];
    final start = startLevels?['comm'];

    if (cur is int) level = cur;
    else if (start is int) level = start;

    level = level.clamp(1, 5);

    setState(() {
      _levelPlayed = level;
      totalRounds = _roundsForLevel(level);
      _levelLoaded = true;
    });
  }

  int _roundsForLevel(int level) {
    switch (level) {
      case 1:
        return 3;
      case 2:
        return 5;
      case 3:
        return 8;
      case 4:
        return 10;
      case 5:
        return 10; // your minimum 10
      default:
        return 5;
    }
  }

  int _optionsCountForLevel(int level) {
    switch (level) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 3;
      case 4:
        return 4;
      case 5:
        return 4;
      default:
        return 3;
    }
  }

  List<_Emotion> _allowedEmotionsForLevel(int level) {
    if (level == 1) return List<_Emotion>.from(_emotionsL1);
    if (level == 2) return List<_Emotion>.from(_emotionsL2);
    if (level == 3) return List<_Emotion>.from(_emotionsL3);
    return List<_Emotion>.from(_emotionsL4); // level 4 & 5
  }

  // ================== GAME FLOW ==================

  void _startSession() {
    _startedAt = DateTime.now();
    _sessionSaved = false;
    _didStartPlaying = false;
  }

  void _startGame() {
    round = 1;
    score = 0;
    mistakes = 0;
    _totalCorrectTimeMs = 0;
    _inputLocked = false;

    _targetEmotion = null;
    _targetSituation = null;
    _options = [];

    _selected = null;
    _showFeedback = false;
    _lastWasCorrect = false;

    _newRound();
  }

  void _newRound() {
    _questionStart = DateTime.now();

    _showFeedback = false;
    _lastWasCorrect = false;
    _selected = null;

    final optionCount = _optionsCountForLevel(_levelPlayed);
    final allowed = _allowedEmotionsForLevel(_levelPlayed);

    if (_levelPlayed == 5) {
      final s = _situationsL5[_rng.nextInt(_situationsL5.length)];
      _targetSituation = s;

      final correct = allowed.firstWhere((e) => e.id == s.correctEmotionId,
          orElse: () => allowed.first); // safety
      _targetEmotion = correct;

      _options = _buildOptions(
          allowed: allowed, correct: correct, count: optionCount);
      setState(() {});

      // no auto audio
      if (_audioAuto) {
        _speak(_situationText(s));
      }
      return;
    }

    // Levels 1-4: emotion face shown
    final correct = allowed[_rng.nextInt(allowed.length)];
    _targetEmotion = correct;
    _targetSituation = null;

    _options =
        _buildOptions(allowed: allowed, correct: correct, count: optionCount);
    setState(() {});

    // no auto audio
    if (_audioAuto) {
      _speak(_emotionLabel(correct));
    }
  }

  List<_Emotion> _buildOptions({
    required List<_Emotion> allowed,
    required _Emotion correct,
    required int count,
  }) {
    final set = <_Emotion>{};
    set.add(correct);

    final pool = List<_Emotion>.from(allowed)..shuffle(_rng);
    for (final e in pool) {
      if (set.length >= count) break;
      if (e.id == correct.id) continue;
      set.add(e);
    }

    final list = set.toList()..shuffle(_rng);

    // Safety: ensure correct exists
    if (!list.any((e) => e.id == correct.id)) {
      if (list.isNotEmpty) list[0] = correct;
    }

    return list.take(count).toList();
  }

  bool _isCorrect(_Emotion picked) {
    return picked.id == _targetEmotion?.id;
  }

  void _finishTimingForCorrect() {
    if (_questionStart == null) return;
    _totalCorrectTimeMs +=
        DateTime.now().difference(_questionStart!).inMilliseconds;
    _questionStart = null;
  }

  // ✅ tap option now = select + speak only (no evaluation, no advance)
  void _onPick(_Emotion picked) {
    if (_inputLocked) return;
    if (!_levelLoaded) return;
    if (_targetEmotion == null) return;
    if (round > totalRounds) return;

    setState(() {
      _selected = picked;
    });

    _speak(_emotionLabel(picked));
  }

  // ✅ Next button = evaluation + feedback colors
  Future<void> _onNext() async {
    if (_inputLocked) return;
    if (!_levelLoaded) return;
    if (_targetEmotion == null) return;
    if (round > totalRounds) return;
    if (_selected == null) return;

    _didStartPlaying = true;

    final picked = _selected!;
    final correct = _isCorrect(picked);

    _inputLocked = true;

    setState(() {
      _showFeedback = true;
      _lastWasCorrect = correct;
    });

    if (correct) {
      _finishTimingForCorrect();
      score++;

      // show green feedback briefly
      await Future.delayed(const Duration(milliseconds: 550));

      round++;
      if (round > totalRounds) {
        if (mounted) setState(() {});
        await _saveSession(completed: true);
        return;
      }

      _inputLocked = false;
      _newRound();
    } else {
      mistakes++;

      // show wrong + correct colors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'خطأ، شوفي الصح ✅' : 'Wrong, see the correct ✅'),
          duration: const Duration(milliseconds: 700),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 900));

      // allow another try on the same question
      if (!mounted) return;
      setState(() {
        _selected = null;
        _showFeedback = false;
      });
      _inputLocked = false;
    }
  }

  double get accuracyPercent {
    final attempts = score + mistakes;
    if (attempts == 0) return 0.0;
    return (score / attempts) * 100.0;
  }

  double get accuracy01 => accuracyPercent / 100.0;

  int get avgMsPerCorrect {
    if (score == 0) return 0;
    return (_totalCorrectTimeMs / score).round();
  }

  Future<bool> _isLevelLockedForComm(String childId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get();
      final data = doc.data();
      final pc = (data?['parentControls'] as Map?)?.cast<String, dynamic>() ?? {};
      final lockLevel =
          (pc['lockLevel'] as Map?)?.cast<String, dynamic>() ?? {};
      return lockLevel['comm'] == true;
    } catch (_) {
      return false;
    }
  }

  int _calcNextLevel({required bool completed}) {
    int next = _levelPlayed;

    if (!completed) {
      next = _levelPlayed - 1;
    } else if (accuracy01 >= 0.85 && mistakes <= 2) {
      next = _levelPlayed + 1;
    } else if (accuracy01 < 0.60) {
      next = _levelPlayed - 1;
    } else {
      next = _levelPlayed;
    }

    return next.clamp(1, 5);
  }

  Future<void> _saveSession({required bool completed}) async {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final endedAt = DateTime.now();
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) return;

    // Respect parent lock for this game
    final locked = await _isLevelLockedForComm(childId);
    final nextLevel = locked ? _levelPlayed : _calcNextLevel(completed: completed);

    final mode = _levelPlayed == 5 ? 'situation' : 'emotion';
    final optionsCount = _optionsCountForLevel(_levelPlayed);

    await GameSessionService.saveSession(
      childId: childId,
      gameId: GameIds.communication,
      startedAt: _startedAt,
      endedAt: endedAt,
      completed: completed,
      metrics: {
        'accuracy': accuracy01,
        'avgTimeMs': avgMsPerCorrect,
        'score': score,
        'mistakes': mistakes,
        'rounds': totalRounds,
        'optionsCount': optionsCount,
        'mode': mode,
      },
      levelPlayed: _levelPlayed,
      levelAfter: nextLevel,
    );

    if (mounted) {
      setState(() {
        _levelPlayed = nextLevel;
        totalRounds = _roundsForLevel(_levelPlayed);
      });
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final finished = round > totalRounds;
    final loading = !_levelLoaded || (_targetEmotion == null) || _options.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: const Text(
          'Communication',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          // ✅ speaker now reads the prompt (not the correct option)
          IconButton(
            tooltip: 'Speak',
            icon: const Icon(Icons.volume_up, color: AppColors.textDark),
            onPressed: () {
              if (_levelPlayed == 5 && _targetSituation != null) {
                _speak(_situationText(_targetSituation!));
              } else {
                _speak(_isAr ? 'ما هو هذا الشعور؟' : 'What emotion is this?');
              }
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _statsBar(finished: finished),
                  const SizedBox(height: 12),

                  // Prompt card
                  _promptCard(),

                  const SizedBox(height: 14),

                  Expanded(
                    child: finished
                        ? _finishPanel(
                            avgMs: avgMsPerCorrect,
                            accuracy: accuracyPercent,
                            onRestart: () {
                              _startSession();
                              _startGame();
                            },
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                            children: _options.map((e) {
                              final isSelected = _selected?.id == e.id;
                              final isCorrectOption = e.id == _targetEmotion!.id;

                              Color borderColor = AppColors.borderSoft;
                              double borderWidth = 1;

                              if (_showFeedback) {
                                if (_lastWasCorrect) {
                                  if (isSelected) {
                                    borderColor = Colors.green;
                                    borderWidth = 3;
                                  }
                                } else {
                                  if (isSelected) {
                                    borderColor = Colors.red;
                                    borderWidth = 3;
                                  } else if (isCorrectOption) {
                                    borderColor = Colors.green;
                                    borderWidth = 3;
                                  }
                                }
                              } else {
                                if (isSelected) {
                                  borderColor = AppColors.textDark;
                                  borderWidth = 2.2;
                                }
                              }

                              return InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => _onPick(e),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLavender,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: borderColor,
                                      width: borderWidth,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(child: _emotionTile(e)),

                                      // ✅ small speaker icon inside each option
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.borderSoft),
                                          ),
                                          child: const Icon(
                                            Icons.volume_up,
                                            size: 18,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),

                  // ✅ NEXT button
                  if (!finished) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cardPeach,
                          foregroundColor: AppColors.textDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        ),
                        onPressed: (_selected == null || _inputLocked) ? null : _onNext,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isAr ? 'التالي' : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statsBar({required bool finished}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          _stat('L', '$_levelPlayed'),
          _stat('Q', finished ? '$totalRounds/$totalRounds' : '$round/$totalRounds'),
          _stat('Score', '$score'),
          _stat('Mistakes', '$mistakes'),
          _stat('Acc', '${accuracyPercent.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptCard() {
    final isLevel5 = _levelPlayed == 5;
    final promptText =
        isLevel5 ? 'Choose the suitable emotion:' : 'What emotion is this?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Text(
            promptText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          if (!isLevel5) ...[
            _bigImage(_targetEmotion!.asset),
            const SizedBox(height: 10),
            Text(
              _isAr ? 'اضغط على الخيار لسماع الكلمة' : 'Tap an option to hear',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
              ),
            ),
          ] else ...[
            // Level 5: situation image + situation text
            _bigImage(_targetSituation!.asset),
            const SizedBox(height: 10),
            Text(
              _situationText(_targetSituation!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isAr ? 'اختار ثم اضغط التالي' : 'Choose then press Next',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigImage(String asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        asset,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: 160,
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Text(
              'Missing image',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
          );
        },
      ),
    );
  }

  // ✅ NEW: emoji mapping for Levels 1–4 options ONLY
  String _emojiForEmotionId(String id) {
    switch (id) {
      case 'happy':
        return '🙂';
      case 'okay':
        return '🙂';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      case 'angry':
        return '😠';
      case 'scared':
        return '😨';
      case 'surprised':
        return '😮';
      case 'tired':
        return '😴';
      case 'confused':
        return '😕';
      case 'disappointed':
        return '😞';
      case 'calm':
        return '😌';
      case 'worried':
        return '😟';
      default:
        return '🙂';
    }
  }

  Widget _emotionTile(_Emotion e) {
    // ✅ Levels 1–4: show emoji options (no repeated face images)
    if (_levelPlayed != 5) {
      final emoji = _emojiForEmotionId(e.id);

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _emotionLabel(e),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      );
    }

    // ✅ Level 5: keep image options exactly as before
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            e.asset,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: const Icon(Icons.face, color: AppColors.textDark),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _emotionLabel(e),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _finishPanel({
    required int avgMs,
    required double accuracy,
    required VoidCallback onRestart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Finished! 🎉',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Accuracy: ${accuracy.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Avg time per correct: ${avgMs}ms',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardLavender,
              foregroundColor: AppColors.textDark,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onPressed: onRestart,
            child: const Text(
              'Play Again',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

// ================== MODELS ==================

class _Emotion {
  final String id;
  final String labelEn;
  final String labelAr;
  final String asset;

  const _Emotion({
    required this.id,
    required this.labelEn,
    required this.labelAr,
    required this.asset,
  });
}

class _Situation {
  final String id;
  final String textEn;
  final String textAr;
  final String asset;
  final String correctEmotionId;

  const _Situation({
    required this.id,
    required this.textEn,
    required this.textAr,
    required this.asset,
    required this.correctEmotionId,
  });
}
