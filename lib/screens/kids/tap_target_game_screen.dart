import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ui/app_colors.dart';
import '../../tracking/game_session_service.dart';
import '../../tracking/game_ids.dart';
import '../../tracking/active_child_provider.dart';

class TapTargetGameScreen extends StatefulWidget {
  const TapTargetGameScreen({super.key});

  @override
  State<TapTargetGameScreen> createState() => _TapTargetGameScreenState();
}

class _TapTargetGameScreenState extends State<TapTargetGameScreen> {
  // ✅ Use AppColors mapping (keeps your style but matches your palette)
  static const bg = AppColors.background;
  static const outer = AppColors.cardPeach;
  static const inner = AppColors.cardLight;
  static const navy = AppColors.textDark;

  static const tileMint = AppColors.cardBlue;
  static const tileButter = AppColors.cardLight;
  static const tileLilac = AppColors.cardLavender;

  final Random _rand = Random();

  // ✅ LEVEL + non-reader
  int _levelPlayed = 3;
  bool _levelLoaded = false;
  bool _canRead = true;

  int _score = 0; // hits
  int _misses = 0;

  double _x = 0.4;
  double _y = 0.5;
  double _size = 74;

  int _secondsLeft = 30;
  int _totalSeconds = 30;

  Timer? _timer;
  Timer? _autoMoveTimer;
  bool _running = false;

  // ✅ TRACKING
  DateTime? _startedAt;
  bool _sessionSaved = false;

  @override
  void initState() {
    super.initState();

    // Load level + canRead first (no guessing), then show UI.
    Future.microtask(() async {
      await _loadChildSettings();
      if (!mounted) return;
      setState(() => _levelLoaded = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoMoveTimer?.cancel();

    // If they exit mid-run -> dropped session
    if (_running && !_sessionSaved) {
      _saveSession(completed: false);
    }

    super.dispose();
  }

  // =================== FIREBASE LOAD ===================

  Future<void> _loadChildSettings() async {
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('children').doc(childId).get();
    final data = doc.data();
    if (data == null) return;

    final placement = data['placement'] as Map<String, dynamic>?;
    final currentLevels = placement?['currentLevels'] as Map<String, dynamic>?;
    final startLevels = placement?['startLevels'] as Map<String, dynamic>?;

    int level = 3;
    final cur = currentLevels?['tap'];
    final start = startLevels?['tap'];
    if (cur is int) level = cur;
    else if (start is int) level = start;

    level = level.clamp(1, 5);

    final canReadVal = data['canRead'];
    final canRead = canReadVal is bool ? canReadVal : true;

    _levelPlayed = level;
    _canRead = canRead;

    // Apply level → session duration defaults
    _totalSeconds = _durationSecondsForLevel(_levelPlayed);
    _secondsLeft = _totalSeconds;
  }

  // =================== LEVEL PARAMETERS ===================

  int _durationSecondsForLevel(int level) {
    // Slightly longer for low levels so they don’t feel rushed
    switch (level) {
      case 1:
        return 35;
      case 2:
        return 32;
      case 3:
        return 30;
      case 4:
        return 28;
      case 5:
        return 25;
      default:
        return 30;
    }
  }

  // Range of target size per level (harder => smaller)
  double _minSizeForLevel(int level) {
    switch (level) {
      case 1:
        return 82;
      case 2:
        return 76;
      case 3:
        return 70;
      case 4:
        return 64;
      case 5:
        return 58;
      default:
        return 70;
    }
  }

  double _maxSizeForLevel(int level) {
    switch (level) {
      case 1:
        return 98;
      case 2:
        return 90;
      case 3:
        return 84;
      case 4:
        return 76;
      case 5:
        return 70;
      default:
        return 84;
    }
  }

  Duration? _autoMoveEveryForLevel(int level) {
    // Auto-move makes it harder. Off for low levels.
    switch (level) {
      case 1:
      case 2:
        return null;
      case 3:
        return const Duration(milliseconds: 1200);
      case 4:
        return const Duration(milliseconds: 900);
      case 5:
        return const Duration(milliseconds: 700);
      default:
        return null;
    }
  }

  int _calcNextLevel({required bool completed, required double accuracy, required double hitsPerMin}) {
    int next = _levelPlayed;

    if (!completed) {
      next = _levelPlayed - 1;
    } else if (accuracy >= 0.85 && hitsPerMin >= 8) {
      next = _levelPlayed + 1;
    } else if (accuracy < 0.60) {
      next = _levelPlayed - 1;
    }

    return next.clamp(1, 5);
  }

  // =================== GAME LOGIC ===================

  void _start() {
    _timer?.cancel();
    _autoMoveTimer?.cancel();

    setState(() {
      _score = 0;
      _misses = 0;
      _totalSeconds = _durationSecondsForLevel(_levelPlayed);
      _secondsLeft = _totalSeconds;
      _running = true;
      _startedAt = DateTime.now();
      _sessionSaved = false;
      _moveTarget();
    });

    // Countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        t.cancel();
        _finish(); // completed=true
      }
    });

    // Auto-move timer (harder levels)
    final auto = _autoMoveEveryForLevel(_levelPlayed);
    if (auto != null) {
      _autoMoveTimer = Timer.periodic(auto, (_) {
        if (!mounted) return;
        if (!_running) return;
        setState(() => _moveTarget());
      });
    }
  }

  Future<void> _finish() async {
    setState(() => _running = false);
    _autoMoveTimer?.cancel();

    await _saveSession(completed: true);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Nice work! 🎯'),
        content: Text('Score: $_score\nMisses: $_misses'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _start();
            },
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    _timer?.cancel();
    _autoMoveTimer?.cancel();
    setState(() {
      _running = false;
      _score = 0;
      _misses = 0;
      _totalSeconds = _durationSecondsForLevel(_levelPlayed);
      _secondsLeft = _totalSeconds;
      _x = 0.4;
      _y = 0.5;
    });
  }

  void _moveTarget() {
    // Keep your safe margins
    _x = _rand.nextDouble() * 0.82 + 0.09;
    _y = _rand.nextDouble() * 0.72 + 0.14;

    final minS = _minSizeForLevel(_levelPlayed);
    final maxS = _maxSizeForLevel(_levelPlayed);
    _size = minS + _rand.nextDouble() * (maxS - minS);
  }

  void _onTapBackground() {
    if (!_running) return;
    setState(() => _misses++);
  }

  void _onTapTarget() {
    if (!_running) return;
    setState(() {
      _score++;
      _moveTarget();
    });
  }

  // =================== SAVE SESSION ===================

  Future<void> _saveSession({required bool completed}) async {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final start = _startedAt;
    if (start == null) return;

    final endedAt = DateTime.now();
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) return;

    final attempts = _score + _misses;
    final accuracy = attempts == 0 ? 0.0 : (_score / attempts); // 0..1

    final durationSec = endedAt.difference(start).inSeconds;
    final mins = durationSec <= 0 ? (_totalSeconds / 60.0) : (durationSec / 60.0);
    final hitsPerMin = mins <= 0 ? 0.0 : (_score / mins);

    final nextLevel = _calcNextLevel(
      completed: completed,
      accuracy: accuracy,
      hitsPerMin: hitsPerMin,
    );

    await GameSessionService.saveSession(
      childId: childId,
      gameId: GameIds.tapTarget,
      startedAt: start,
      endedAt: endedAt,
      completed: completed,
      metrics: {
        // ✅ agreed metrics
        'accuracy': accuracy,
        'hitsPerMin': hitsPerMin,
        // extras
        'hits': _score,
        'misses': _misses,
      },
      levelPlayed: _levelPlayed,
      levelAfter: nextLevel,
    );

    // So next run uses the updated level immediately
    if (mounted) {
      setState(() {
        _levelPlayed = nextLevel;
        _totalSeconds = _durationSecondsForLevel(_levelPlayed);
        _secondsLeft = _totalSeconds;
      });
    }
  }

  // =================== UI ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: navy),
        title: const Text(
          'Tap the Target',
          style: TextStyle(color: navy, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: !_levelLoaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: outer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inner,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _Chip(label: 'Score', value: '$_score', color: tileMint),
                          const SizedBox(width: 10),
                          _Chip(label: 'Misses', value: '$_misses', color: tileButter),
                          const Spacer(),
                          _Chip(label: 'Time', value: '${_secondsLeft}s', color: tileLilac),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final fieldW = constraints.maxWidth;
                            final fieldH = constraints.maxHeight;

                            final left = (fieldW - _size) * _x;
                            final top = (fieldH - _size) * _y;

                            return GestureDetector(
                              onTap: _onTapBackground,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.9),
                                    width: 3,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: left,
                                      top: top,
                                      child: GestureDetector(
                                        onTap: _onTapTarget,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          width: _size,
                                          height: _size,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: tileMint.withOpacity(0.95),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: tileMint.withOpacity(0.35),
                                                blurRadius: 14,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.ads_click_rounded,
                                              color: navy,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Instruction overlay when not running
                                    if (!_running)
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: AppColors.borderSoft),
                                          ),
                                          child: _canRead
                                              ? const Text(
                                                  'Press Start, then tap the circle 🎯',
                                                  style: TextStyle(
                                                    color: navy,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.play_arrow_rounded, color: navy),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.ads_click_rounded, color: navy),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.circle, color: navy, size: 10),
                                                  ],
                                                ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tileMint,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              onPressed: _running ? null : _start,
                              child: _canRead
                                  ? const Text(
                                      'Start',
                                      style: TextStyle(
                                        color: navy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.play_arrow_rounded,
                                      color: navy,
                                      size: 32,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tileButter,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              onPressed: _reset,
                              child: _canRead
                                  ? const Text(
                                      'Reset',
                                      style: TextStyle(
                                        color: navy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      color: navy,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
  });

  static const navy = AppColors.textDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
