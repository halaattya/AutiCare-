import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ui/app_colors.dart';
import '../../tracking/game_session_service.dart';
import '../../tracking/game_ids.dart';
import '../../tracking/active_child_provider.dart';

class MatchGameScreen extends StatefulWidget {
  const MatchGameScreen({super.key});

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  final _rng = Random();

  // ✅ LEVELS
  int _levelPlayed = 3; // default until loaded
  bool _levelLoaded = false;

  int totalQuestions = 10;

  int question = 1;
  int score = 0;
  int mistakes = 0;

  bool _inputLocked = false;

  DateTime? _questionStart;
  int _totalCorrectTimeMs = 0;

  // ✅ TRACKING
  late DateTime _startedAt;
  bool _sessionSaved = false;
  bool _didStartPlaying = false;

  // Controlled by level (do not toggle)
  bool matchByColorToo = true;

  // ✅ Avoid red flash by not using late
  _CardSpec? target;
  List<_CardSpec> options = [];

  @override
  void initState() {
    super.initState();
    _startSession();

    Future.microtask(() async {
      await _loadLevelFromFirebase();
      if (!mounted) return;
      _startGame();
    });
  }

  @override
  void dispose() {
    if (_didStartPlaying && !_sessionSaved) {
      _saveSession(completed: false);
    }
    super.dispose();
  }

  // ================= LEVEL =================

  Future<void> _loadLevelFromFirebase() async {
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) {
      setState(() => _levelLoaded = true);
      return;
    }

    final doc =
        await FirebaseFirestore.instance.collection('children').doc(childId).get();
    final data = doc.data();
    if (data == null) {
      setState(() => _levelLoaded = true);
      return;
    }

    final placement = data['placement'] as Map<String, dynamic>?;
    final currentLevels = placement?['currentLevels'] as Map<String, dynamic>?;
    final startLevels = placement?['startLevels'] as Map<String, dynamic>?;

    int level = 3;
    final cur = currentLevels?['match'];
    final start = startLevels?['match'];

    if (cur is int) level = cur;
    else if (start is int) level = start;

    level = level.clamp(1, 5);

    totalQuestions = _questionsForLevel(level);
    matchByColorToo = level >= 3; // ✅ L1-L2 shape only, L3-L5 shape+color

    setState(() {
      _levelPlayed = level;
      _levelLoaded = true;
    });
  }

  int _questionsForLevel(int level) {
    switch (level) {
      case 1:
        return 6;
      case 2:
        return 8;
      case 3:
        return 10;
      case 4:
        return 12;
      case 5:
        return 15;
      default:
        return 10;
    }
  }

  int _optionsCountForLevel(int level) {
    // ✅ Your rules:
    // L1: 3 options
    // L2-5: 4 options
    return level == 1 ? 3 : 4;
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

  // ================= GAME =================

  void _startSession() {
    _startedAt = DateTime.now();
    _sessionSaved = false;
    _didStartPlaying = false;
  }

  void _startGame() {
    question = 1;
    score = 0;
    mistakes = 0;
    _totalCorrectTimeMs = 0;
    _inputLocked = false;

    target = null;
    options = [];

    _newQuestion();
  }

  void _newQuestion() {
    _questionStart = DateTime.now();

    final optCount = _optionsCountForLevel(_levelPlayed);

    // ✅ target depends on level palette
    final t = _randomTargetForLevel(_levelPlayed);
    target = t;

    options = _buildOptionsForLevel(
      level: _levelPlayed,
      target: t,
      optionCount: optCount,
    );

    setState(() {});
  }

  _CardSpec _randomTargetForLevel(int level) {
    final shape = _Shape.values[_rng.nextInt(_Shape.values.length)];

    // ✅ Color palette by level
    final color = _randomColorForLevel(level);
    return _CardSpec(shape: shape, color: color);
  }

  Color _randomColorForLevel(int level) {
    // L1-L2: very light pastel (sensory safe)
    // L3: light-but-clear
    // L4-L5: normal colors (but still clean)
    if (level == 1) return _CardSpec.randomPastelVeryLight(_rng);
    if (level == 2) return _CardSpec.randomPastelLight(_rng);
    if (level == 3) return _CardSpec.randomPastelLight(_rng);
    return _CardSpec.randomNormalColor(_rng);
  }

  List<_CardSpec> _buildOptionsForLevel({
    required int level,
    required _CardSpec target,
    required int optionCount,
  }) {
    final set = <_CardSpec>{};
    set.add(target);

    if (level == 1) {
      // ✅ L1: Shape only, 3 options, very light colors
      // - 1 correct shape
      // - 2 different shapes
      while (set.length < optionCount) {
        final s = _CardSpec.randomShapeDifferentFrom(_rng, target.shape);
        set.add(_CardSpec(shape: s, color: _CardSpec.randomPastelVeryLight(_rng)));
      }
    } else if (level == 2) {
      // ✅ L2: Shape only, 4 options, light colors
      while (set.length < optionCount) {
        final s = _CardSpec.randomShapeDifferentFrom(_rng, target.shape);
        set.add(_CardSpec(shape: s, color: _CardSpec.randomPastelLight(_rng)));
      }
    } else if (level == 3) {
      // ✅ L3: Shape + Color, ONLY ONE exact match.
      // Others:
      // - same shape diff color
      // - same color diff shape
      // - diff shape diff color
      final d1 = _CardSpec(
        shape: target.shape,
        color: _CardSpec.randomColorDifferentFromLevel(_rng, level, target.color),
      );
      final d2 = _CardSpec(
        shape: _CardSpec.randomShapeDifferentFrom(_rng, target.shape),
        color: target.color,
      );
      final d3 = _CardSpec(
        shape: _CardSpec.randomShapeDifferentFrom(_rng, target.shape),
        color: _CardSpec.randomColorDifferentFromLevel(_rng, level, target.color),
      );
      set.addAll([d1, d2, d3]);

      // Safety: ensure correct exists and only once
      while (set.length < optionCount) {
        set.add(_CardSpec(
          shape: _Shape.values[_rng.nextInt(_Shape.values.length)],
          color: _randomColorForLevel(level),
        ));
      }
    } else if (level == 4) {
      // ✅ L4: Shape + Color
      // options: correct, same shape, same color, totally different
      final sameShape = _CardSpec(
        shape: target.shape,
        color: _CardSpec.randomColorDifferentFromLevel(_rng, level, target.color),
      );
      final sameColor = _CardSpec(
        shape: _CardSpec.randomShapeDifferentFrom(_rng, target.shape),
        color: target.color,
      );
      final totallyDifferent = _CardSpec(
        shape: _CardSpec.randomShapeDifferentFrom(_rng, target.shape),
        color: _CardSpec.randomColorDifferentFromLevel(_rng, level, target.color),
      );

      set.addAll([sameShape, sameColor, totallyDifferent]);

      while (set.length < optionCount) {
        set.add(_CardSpec(
          shape: _Shape.values[_rng.nextInt(_Shape.values.length)],
          color: _randomColorForLevel(level),
        ));
      }
    } else {
      // ✅ L5: Shape + Color, harder (close distractors)
      // - one similar shape (same color)
      // - one similar color (same shape)
      // - one both kinda close but still wrong
      final similarShape = _CardSpec(
        shape: _CardSpec.similarShapeTo(_rng, target.shape),
        color: target.color,
      );

      final similarColor = _CardSpec(
        shape: target.shape,
        color: _CardSpec.similarColorTo(_rng, target.color),
      );

      // both "close" but must NOT equal correct
      final closeBoth = _CardSpec(
        shape: _CardSpec.similarShapeTo(_rng, target.shape),
        color: _CardSpec.similarColorTo(_rng, target.color),
      );

      set.addAll([similarShape, similarColor, closeBoth]);

      // Safety fill
      while (set.length < optionCount) {
        set.add(_CardSpec(
          shape: _CardSpec.similarShapeTo(_rng, target.shape),
          color: _CardSpec.randomColorDifferentFromLevel(_rng, level, target.color),
        ));
      }
    }

    final list = set.toList()..shuffle(_rng);

    // ✅ final safety: ensure target is present
    if (!list.any((o) =>
        o.shape == target.shape && o.color.value == target.color.value)) {
      if (list.isNotEmpty) list[0] = target;
      list.shuffle(_rng);
    }

    // Ensure exact count (in case set got larger)
    return list.take(optionCount).toList();
  }

  bool _isCorrect(_CardSpec picked) {
    final t = target;
    if (t == null) return false;

    if (matchByColorToo) {
      return picked.shape == t.shape && picked.color.value == t.color.value;
    }
    return picked.shape == t.shape;
  }

  void _finishTimingForCorrect() {
    if (_questionStart == null) return;
    _totalCorrectTimeMs +=
        DateTime.now().difference(_questionStart!).inMilliseconds;
    _questionStart = null;
  }

  void _onPick(_CardSpec picked) {
    if (_inputLocked) return;
    if (!_levelLoaded) return;
    if (question > totalQuestions) return;
    if (target == null) return;

    _didStartPlaying = true;

    if (_isCorrect(picked)) {
      _finishTimingForCorrect();
      score++;

      question++;
      if (question > totalQuestions) {
        setState(() {});
        _saveSession(completed: true);
        return;
      }
      _newQuestion();
    } else {
      _inputLocked = true;
      mistakes++;

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Try again 🙂'),
          duration: Duration(milliseconds: 380),
        ),
      );

      Future.delayed(const Duration(milliseconds: 450), () {
        _inputLocked = false;
      });
    }
  }

  double get accuracyPercent {
    final attempts = score + mistakes;
    if (attempts == 0) return 0;
    return (score / attempts) * 100.0;
  }

  double get accuracy01 => accuracyPercent / 100.0;

  int get avgMsPerCorrect {
    if (score == 0) return 0;
    return (_totalCorrectTimeMs / score).round();
  }

  Future<void> _saveSession({required bool completed}) async {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final endedAt = DateTime.now();
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) return;

    final nextLevel = _calcNextLevel(completed: completed);

    await GameSessionService.saveSession(
      childId: childId,
      gameId: GameIds.shapeMatching,
      startedAt: _startedAt,
      endedAt: endedAt,
      completed: completed,
      metrics: {
        'accuracy': accuracy01,
        'avgTimeMs': avgMsPerCorrect,
        'score': score,
        'mistakes': mistakes,
        'mode': matchByColorToo ? 'shape_color' : 'shape_only',
        'optionsCount': _optionsCountForLevel(_levelPlayed),
      },
      levelPlayed: _levelPlayed,
      levelAfter: nextLevel,
    );

    if (mounted) {
      setState(() {
        _levelPlayed = nextLevel;
        totalQuestions = _questionsForLevel(_levelPlayed);
        matchByColorToo = _levelPlayed >= 3;
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final finished = question > totalQuestions;

    // ✅ prevent any flash / null crashes
    final loading = !_levelLoaded || target == null || options.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: const Text(
          'Shape Matching',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            tooltip: 'Mode is fixed by level',
            icon: const Icon(Icons.tune, color: AppColors.textDark),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mode is fixed by the level 🙂'),
                  duration: Duration(milliseconds: 450),
                ),
              );
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      children: [
                        _stat(
                          'Q',
                          finished
                              ? '$totalQuestions/$totalQuestions'
                              : '$question/$totalQuestions',
                        ),
                        _stat('Score', '$score'),
                        _stat('Mistakes', '$mistakes'),
                        _stat('Acc', '${accuracyPercent.toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      matchByColorToo
                          ? 'Mode: Match Shape + Color'
                          : 'Mode: Match Shape Only',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Match this:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ShapePreview(
                          shape: target!.shape,
                          color: target!.color,
                          size: 82,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          matchByColorToo
                              ? '${_shapeName(target!.shape)} + ${_colorName(target!.color)}'
                              : _shapeName(target!.shape),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            childAspectRatio: 1.1,
                            children: options.map((opt) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => _onPick(opt),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.cardLavender,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: AppColors.borderSoft),
                                  ),
                                  child: Center(
                                    child: _ShapePreview(
                                      shape: opt.shape,
                                      color: opt.color,
                                      size: 64,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
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

  String _shapeName(_Shape s) {
    switch (s) {
      case _Shape.circle:
        return 'Circle';
      case _Shape.square:
        return 'Square';
      case _Shape.triangle:
        return 'Triangle';
      case _Shape.rectangle:
        return 'Rectangle';
      case _Shape.hexagon:
        return 'Hexagon';
      case _Shape.diamond:
        return 'Diamond';
      case _Shape.star:
        return 'Star';
    }
  }

  String _colorName(Color c) {
    // Friendly names for normal colors + pastels
    if (c.value == Colors.red.value) return 'Red';
    if (c.value == Colors.blue.value) return 'Blue';
    if (c.value == Colors.green.value) return 'Green';
    if (c.value == Colors.amber.value) return 'Yellow';
    if (c.value == Colors.purple.value) return 'Purple';
    if (c.value == Colors.orange.value) return 'Orange';
    if (c.value == Colors.teal.value) return 'Teal';
    return 'Color';
  }
}

// ======================== MODEL + PAINTER (mostly unchanged) ========================

enum _Shape { circle, square, triangle, rectangle, hexagon, diamond, star }

class _CardSpec {
  final _Shape shape;
  final Color color;

  const _CardSpec({required this.shape, required this.color});

  // Normal colors for L4-L5
  static const _normalColors = <Color>[
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  // Very light pastels (sensory-safe)
  static const _pastelVeryLight = <Color>[
    Color(0xFFFFE1E8), // very light pink
    Color(0xFFE6F4FF), // very light blue
    Color(0xFFE9F7EF), // very light mint
    Color(0xFFFFF3D6), // very light yellow
    Color(0xFFF1E6FF), // very light lavender
    Color(0xFFFFEAD9), // very light peach
  ];

  // Light pastels (still calm, but a bit clearer)
  static const _pastelLight = <Color>[
    Color(0xFFFFC7D4), // light pink
    Color(0xFFCFEAFF), // light blue
    Color(0xFFCDEFD9), // light mint
    Color(0xFFFFE6B8), // light yellow
    Color(0xFFE2D1FF), // light lavender
    Color(0xFFFFD7B8), // light peach
  ];

  static _CardSpec random(Random rng) {
    final shape = _Shape.values[rng.nextInt(_Shape.values.length)];
    final color = _normalColors[rng.nextInt(_normalColors.length)];
    return _CardSpec(shape: shape, color: color);
  }

  static Color randomPastelVeryLight(Random rng) =>
      _pastelVeryLight[rng.nextInt(_pastelVeryLight.length)];

  static Color randomPastelLight(Random rng) =>
      _pastelLight[rng.nextInt(_pastelLight.length)];

  static Color randomNormalColor(Random rng) =>
      _normalColors[rng.nextInt(_normalColors.length)];

  static Color randomColorDifferentFromLevel(Random rng, int level, Color notThis) {
    Color c;
    do {
      if (level <= 2) {
        c = (level == 1) ? randomPastelVeryLight(rng) : randomPastelLight(rng);
      } else if (level == 3) {
        c = randomPastelLight(rng);
      } else {
        c = randomNormalColor(rng);
      }
    } while (c.value == notThis.value);
    return c;
  }

  static _Shape randomShapeDifferentFrom(Random rng, _Shape notThis) {
    _Shape s;
    do {
      s = _Shape.values[rng.nextInt(_Shape.values.length)];
    } while (s == notThis);
    return s;
  }

  // ✅ Similar shape groups for Level 5 difficulty
  static _Shape similarShapeTo(Random rng, _Shape base) {
    final groups = <List<_Shape>>[
      [_Shape.square, _Shape.rectangle, _Shape.diamond],
      [_Shape.circle],
      [_Shape.triangle],
      [_Shape.hexagon],
      [_Shape.star],
    ];

    final group = groups.firstWhere(
      (g) => g.contains(base),
      orElse: () => [_Shape.square, _Shape.rectangle, _Shape.diamond],
    );

    if (group.length == 1) {
      // no close neighbor -> fallback to another "common confusion" group
      final fallback = [_Shape.square, _Shape.rectangle, _Shape.diamond];
      if (fallback.contains(base) && fallback.length > 1) {
        final list = List<_Shape>.from(fallback)..remove(base);
        return list[rng.nextInt(list.length)];
      }
      return randomShapeDifferentFrom(rng, base);
    }

    final list = List<_Shape>.from(group)..remove(base);
    return list[rng.nextInt(list.length)];
  }

  // ✅ Similar color pairs for Level 5 difficulty
  static Color similarColorTo(Random rng, Color base) {
    // map base to a "close" alternative
    final b = base.value;

    // If base isn't in normal palette (pastel), just return a different pastel.
    if (_pastelVeryLight.any((c) => c.value == b)) {
      Color c;
      do {
        c = randomPastelVeryLight(rng);
      } while (c.value == b);
      return c;
    }
    if (_pastelLight.any((c) => c.value == b)) {
      Color c;
      do {
        c = randomPastelLight(rng);
      } while (c.value == b);
      return c;
    }

    // Normal close pairs
    if (b == Colors.blue.value) return Colors.teal;
    if (b == Colors.teal.value) return Colors.blue;

    if (b == Colors.red.value) return Colors.orange;
    if (b == Colors.orange.value) return Colors.red;

    if (b == Colors.purple.value) return Colors.blue;

    if (b == Colors.green.value) return Colors.teal;

    // fallback: any different normal
    Color c;
    do {
      c = randomNormalColor(rng);
    } while (c.value == b);
    return c;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CardSpec && shape == other.shape && color.value == other.color.value;

  @override
  int get hashCode => shape.hashCode ^ color.value.hashCode;
}

class _ShapePreview extends StatelessWidget {
  final _Shape shape;
  final Color color;
  final double size;

  const _ShapePreview({required this.shape, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: ValueKey('${shape.name}-${color.value}'),
      size: Size(size, size),
      painter: _ShapePainter(shape: shape, color: color),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final _Shape shape;
  final Color color;

  _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    switch (shape) {
      case _Shape.circle:
        canvas.drawCircle(Offset(w / 2, h / 2), w / 2, paint);
        break;

      case _Shape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 4, w - 8, h - 8),
            const Radius.circular(12),
          ),
          paint,
        );
        break;

      case _Shape.rectangle:
        final rectW = w * 0.78;
        final rectH = h * 0.55;
        final left = (w - rectW) / 2;
        final top = (h - rectH) / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, rectW, rectH),
            const Radius.circular(12),
          ),
          paint,
        );
        break;

      case _Shape.triangle:
        final path = Path()
          ..moveTo(w / 2, 6)
          ..lineTo(w - 6, h - 6)
          ..lineTo(6, h - 6)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case _Shape.diamond:
        final path = Path()
          ..moveTo(w / 2, 6)
          ..lineTo(w - 6, h / 2)
          ..lineTo(w / 2, h - 6)
          ..lineTo(6, h / 2)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case _Shape.hexagon:
        final cx = w / 2, cy = h / 2;
        final r = w * 0.45;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (pi / 3) * i - pi / 6;
          final x = cx + cos(angle) * r;
          final y = cy + sin(angle) * r;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;

      case _Shape.star:
        final cx = w / 2, cy = h / 2;
        final rOuter = w * 0.48;
        final rInner = w * 0.22;
        final path = Path();
        for (int i = 0; i < 10; i++) {
          final angle = (pi / 5) * i - pi / 2;
          final r = i.isEven ? rOuter : rInner;
          final x = cx + cos(angle) * r;
          final y = cy + sin(angle) * r;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color.value != color.value;
  }
}
