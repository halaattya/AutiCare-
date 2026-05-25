import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ui/app_colors.dart';
import '../../tracking/game_session_service.dart';
import '../../tracking/game_ids.dart';
import '../../tracking/active_child_provider.dart';

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({super.key});

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  // ✅ NOW 12 images (you will add 9..12.png)
  final List<String> _baseImages = const [
    'assets/memory/1.png',
    'assets/memory/2.png',
    'assets/memory/3.png',
    'assets/memory/4.png',
    'assets/memory/5.png',
    'assets/memory/6.png',
    'assets/memory/7.png',
    'assets/memory/8.png',
    'assets/memory/9.png',
    'assets/memory/10.png',
    'assets/memory/11.png',
    'assets/memory/12.png',
  ];

  List<_CardModel> _cards = [];
  int? _firstIndex;
  bool _isBusy = false;
  Timer? _previewTimer;

  // ✅ LEVELS
  int _levelPlayed = 3; // default until loaded
  bool _levelLoaded = false;

  // ✅ TRACKING
  late DateTime _startedAt;
  int _mistakes = 0;
  bool _sessionSaved = false;
  bool _didStartPlaying = false;

  @override
  void initState() {
    super.initState();
    _startSession();

    // Load level first, then build the board (no guessing).
    Future.microtask(() async {
      await _loadLevelFromFirebase();
      if (!mounted) return;
      _resetGame();
    });
  }

  @override
  void dispose() {
    _previewTimer?.cancel();

    // If they leave mid-game after starting, store as dropped
    if (_didStartPlaying && !_sessionSaved) {
      _saveSession(completed: false);
    }

    super.dispose();
  }

  void _startSession() {
    _startedAt = DateTime.now();
    _mistakes = 0;
    _sessionSaved = false;
    _didStartPlaying = false;
  }

  int _pairsForLevel(int level) {
    // ✅ EXACTLY as you asked:
    // L1: 8 cards  -> 4 pairs
    // L2: 12 cards -> 6 pairs
    // L3: 16 cards -> 8 pairs
    // L4: 20 cards -> 10 pairs
    // L5: 24 cards -> 12 pairs
    switch (level) {
      case 1:
        return 4;
      case 2:
        return 6;
      case 3:
        return 8;
      case 4:
        return 10;
      case 5:
        return 12;
      default:
        return 8;
    }
  }

  Duration _previewDurationForLevel(int level) {
    // ✅ EXACTLY as you asked:
    // L1: 5s, L2: 5s, L3: 4s, L4: 4s, L5: 3s
    switch (level) {
      case 1:
        return const Duration(seconds: 5);
      case 2:
        return const Duration(seconds: 5);
      case 3:
        return const Duration(seconds: 4);
      case 4:
        return const Duration(seconds: 4);
      case 5:
        return const Duration(seconds: 3);
      default:
        return const Duration(seconds: 4);
    }
  }

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

    // Prefer currentLevels.memory, otherwise fall back to startLevels.memory, otherwise default 3.
    final placement = data['placement'] as Map<String, dynamic>?;
    final currentLevels = placement?['currentLevels'] as Map<String, dynamic>?;
    final startLevels = placement?['startLevels'] as Map<String, dynamic>?;

    int level = 3;
    final cur = currentLevels?['memory'];
    final start = startLevels?['memory'];

    if (cur is int) level = cur;
    else if (start is int) level = start;

    level = level.clamp(1, 5);

    setState(() {
      _levelPlayed = level;
      _levelLoaded = true;
    });
  }

  void _resetGame() {
    _previewTimer?.cancel();
    final rng = Random();

    final pairs = _pairsForLevel(_levelPlayed);

    // Pick N unique images, duplicate for pairs, shuffle
    final chosen = List<String>.from(_baseImages)..shuffle(rng);
    final selected = chosen.take(pairs).toList();
    final images = [...selected, ...selected]..shuffle(rng);

    _cards = images.map((p) => _CardModel(imagePath: p)).toList();

    _firstIndex = null;
    _isBusy = false;

    for (final c in _cards) {
      c.isFaceUp = true;
      c.isMatched = false;
    }

    setState(() {});

    _previewTimer = Timer(_previewDurationForLevel(_levelPlayed), () {
      if (!mounted) return;
      setState(() {
        for (final c in _cards) {
          c.isFaceUp = false;
        }
      });
    });
  }

  bool get _allMatched => _cards.every((c) => c.isMatched);

  Future<void> _onCardTap(int index) async {
    if (_isBusy) return;
    if (!_levelLoaded) return;

    _didStartPlaying = true;

    final card = _cards[index];
    if (card.isMatched || card.isFaceUp) return;

    setState(() => card.isFaceUp = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _cards[_firstIndex!];
    final second = _cards[index];

    _isBusy = true;
    await Future.delayed(const Duration(milliseconds: 650));

    if (first.imagePath == second.imagePath) {
      setState(() {
        first.isMatched = true;
        second.isMatched = true;
      });
    } else {
      _mistakes++;
      setState(() {
        first.isFaceUp = false;
        second.isFaceUp = false;
      });
    }

    _firstIndex = null;
    _isBusy = false;

    if (_allMatched && mounted) {
      await _saveSession(completed: true);
      _showWinDialog();
    }
  }

  int _calcNextLevel({
    required bool completed,
    required double accuracy,
    required int currentLevel,
    required int mistakes,
  }) {
    int next = currentLevel;

    // Simple, explainable adaptation (MVP)
    if (!completed) {
      next = currentLevel - 1;
    } else if (accuracy >= 0.85 && mistakes <= 2) {
      next = currentLevel + 1;
    } else if (accuracy < 0.60) {
      next = currentLevel - 1;
    } else {
      next = currentLevel;
    }

    return next.clamp(1, 5);
  }

  Future<void> _saveSession({required bool completed}) async {
    if (_sessionSaved) return;
    _sessionSaved = true;

    final endedAt = DateTime.now();
    final childId = await ActiveChildProvider.getActiveChildId();
    if (childId == null) return;

    final totalPairs = _cards.length ~/ 2;

    final denom = (totalPairs + _mistakes);
    final acc = denom == 0 ? 0.0 : (totalPairs / denom);

    final nextLevel = _calcNextLevel(
      completed: completed,
      accuracy: acc,
      currentLevel: _levelPlayed,
      mistakes: _mistakes,
    );

    await GameSessionService.saveSession(
      childId: childId,
      gameId: GameIds.memory,
      startedAt: _startedAt,
      endedAt: endedAt,
      completed: completed,
      metrics: {
        'score': totalPairs,
        'accuracy': acc,
        'mistakes': _mistakes,
      },
      levelPlayed: _levelPlayed,
      levelAfter: nextLevel,
    );

    if (mounted) {
      setState(() => _levelPlayed = nextLevel);
    }
  }

  void _showWinDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Great job! 🎉'),
        content: const Text('You matched all the cards.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startSession();
              _resetGame();
            },
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Keep 4 columns (cards stay big and readable)
    const crossAxisCount = 4;

    // ✅ Center grid vertically for small levels (8/12/16 cards)
    final shouldCenter = _levelLoaded && _cards.length <= 16;

    final grid = GridView.builder(
      padding: const EdgeInsets.all(14),
      shrinkWrap: shouldCenter, // important for vertical centering
      physics: shouldCenter
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final c = _cards[index];
        return GestureDetector(
          onTap: () => _onCardTap(index),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: c.isFaceUp || c.isMatched
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(c.imagePath, fit: BoxFit.cover),
                  )
                : const Icon(Icons.extension_rounded,
                    size: 40, color: AppColors.textSoft),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardPeach,
        elevation: 0,
        title: const Text(
          'Memory Game',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: (!_levelLoaded || _cards.isEmpty)
    ? const Center(child: CircularProgressIndicator())
    : shouldCenter
        ? Center(child: grid)
        : grid,

    );
  }
}

class _CardModel {
  _CardModel({required this.imagePath});
  final String imagePath;
  bool isFaceUp = false;
  bool isMatched = false;
}
