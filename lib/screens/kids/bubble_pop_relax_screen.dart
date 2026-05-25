import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BubblePopRelaxScreen extends StatefulWidget {
  const BubblePopRelaxScreen({super.key});

  @override
  State<BubblePopRelaxScreen> createState() => _BubblePopRelaxScreenState();
}

class _BubblePopRelaxScreenState extends State<BubblePopRelaxScreen> {
  // Match your app palette (soft pastel)
  static const bg = Color(0xFFFFF7ED);
  static const navy = Color(0xFF1F2A44);

  final Random _rand = Random();
  final List<_Bubble> _bubbles = [];

  Timer? _spawnTimer;
  Timer? _tickTimer;

  bool _paused = false;

  // Tuning (calm mode)
  final int _maxBubblesOnScreen = 10;
  final Duration _spawnEvery = const Duration(milliseconds: 900);
  final Duration _tickEvery = const Duration(milliseconds: 35);
  final double _minSpeed = 0.35; // slow
  final double _maxSpeed = 0.85;

  Size _screen = Size.zero;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _start() {
    _spawnTimer?.cancel();
    _tickTimer?.cancel();

    _spawnTimer = Timer.periodic(_spawnEvery, (_) {
      if (_paused) return;
      if (_bubbles.length >= _maxBubblesOnScreen) return;
      _spawnBubble();
    });

    _tickTimer = Timer.periodic(_tickEvery, (_) {
      if (_paused) return;
      _tick();
    });
  }

  void _spawnBubble() {
    if (_screen == Size.zero) return;

    final radius = _rand.nextDouble() * 24 + 26; // 26..50
    final x = _rand.nextDouble() * (_screen.width - radius * 2);
    final y = _screen.height + radius * 2;

    final speed = _minSpeed + _rand.nextDouble() * (_maxSpeed - _minSpeed);

    final colors = const [
      Color(0xFFDDF3F2), // mint
      Color(0xFFFFE8B3), // butter
      Color(0xFFF6D1B6), // peach
      Color(0xFFE9E0FF), // lilac
    ];

    _bubbles.add(
      _Bubble(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        x: x,
        y: y,
        r: radius,
        speed: speed,
        color: colors[_rand.nextInt(colors.length)],
      ),
    );

    setState(() {});
  }

  void _tick() {
    if (_screen == Size.zero) return;

    for (final b in _bubbles) {
      if (b.isPopping) continue;
      b.y -= b.speed * 3.2; // upward movement
    }

    // Remove bubbles that floated away
    _bubbles.removeWhere((b) => b.y + b.r * 2 < -20);

    setState(() {});
  }

  void _popBubble(_Bubble b) {
    if (b.isPopping) return;

    setState(() => b.isPopping = true);

    // After pop animation, remove
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _bubbles.removeWhere((x) => x.id == b.id));
    });
  }

  void _reset() {
    setState(() => _bubbles.clear());
  }

  @override
  Widget build(BuildContext context) {
    _screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text(
          'Bubble Pop Relax',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: navy),
        actions: [
          IconButton(
            onPressed: () => setState(() => _paused = !_paused),
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            tooltip: _paused ? 'Resume' : 'Pause',
          ),
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2D1B3), // outer soft peach
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7EA), // inner creamy
              borderRadius: BorderRadius.circular(26),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // Hint
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.spa_rounded, color: navy),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _paused ? 'Paused… take a breath 🌿' : 'Pop the bubbles slowly 🫧',
                              style: const TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bubbles
                  ..._bubbles.map((b) {
                    return Positioned(
                      left: b.x,
                      top: b.y,
                      child: GestureDetector(
                        onTap: () => _popBubble(b),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: b.isPopping ? 1.35 : 1.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: b.isPopping ? 0.0 : 1.0,
                            child: Container(
                              width: b.r * 2,
                              height: b.r * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: b.color.withOpacity(0.8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: b.color.withOpacity(0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble {
  final String id;
  double x;
  double y;
  final double r;
  final double speed;
  final Color color;
  bool isPopping;

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.color,
    this.isPopping = false,
  });
}
