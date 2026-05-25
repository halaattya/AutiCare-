import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class ReactionTimeGameScreen extends StatefulWidget {
  const ReactionTimeGameScreen({super.key});

  @override
  State<ReactionTimeGameScreen> createState() => _ReactionTimeGameScreenState();
}

class _ReactionTimeGameScreenState extends State<ReactionTimeGameScreen> {
  // Match your app palette
  static const bg = Color(0xFFFFF7ED);
  static const outer = Color(0xFFF2D1B3);
  static const inner = Color(0xFFFFF2DA);
  static const navy = Color(0xFF1F2A44);

  // Game colors (soft + non-stimulating)
  static const waitColor = Color(0xFFE9E0FF);   // lilac
  static const readyColor = Color(0xFFDDF3F2);  // mint
  static const tooSoonColor = Color(0xFFFFE8B3); // butter (no scary red)

  final Random _rand = Random();
  Timer? _timer;

  bool _isRunning = false;
  bool _isReady = false;
  DateTime? _readyAt;

  String _message = 'Tap START, then wait until it turns green.';
  Color _panelColor = waitColor;

  int? _lastMs;
  int? _bestMs;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();

    setState(() {
      _isRunning = true;
      _isReady = false;
      _readyAt = null;
      _panelColor = waitColor;
      _message = 'Wait… focus on the screen 👀';
    });

    // Random wait (1.5s to 4s)
    final delayMs = 1500 + _rand.nextInt(2500);

    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _readyAt = DateTime.now();
        _panelColor = readyColor;
        _message = 'TAP NOW!';
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isReady = false;
      _readyAt = null;
      _panelColor = waitColor;
      _message = 'Tap START, then wait until it turns green.';
      _lastMs = null;
    });
  }

  void _handleTap() {
    if (!_isRunning) return;

    // Tapped too early
    if (!_isReady) {
      _timer?.cancel();
      setState(() {
        _panelColor = tooSoonColor;
        _message = 'Too soon 🙂 Let’s try again.';
        _isRunning = false;
        _isReady = false;
        _readyAt = null;
      });
      return;
    }

    // Correct tap
    final now = DateTime.now();
    final ms = now.difference(_readyAt!).inMilliseconds;

    setState(() {
      _lastMs = ms;
      _bestMs = (_bestMs == null) ? ms : min(_bestMs!, ms);
      _message = 'Great! Your time: ${ms} ms 🎉';
      _isRunning = false;
      _isReady = false;
      _readyAt = null;
      _panelColor = waitColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: navy),
        title: const Text(
          'Reaction Time',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        actions: [
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
            ),
            child: Column(
              children: [
                // Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_rounded, color: navy),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message,
                          style: const TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tap area
                Expanded(
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _isRunning
                              ? (_isReady ? 'TAP!' : 'WAIT')
                              : 'READY',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Stats + buttons
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        title: 'Last',
                        value: _lastMs == null ? '--' : '${_lastMs} ms',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatChip(
                        title: 'Best',
                        value: _bestMs == null ? '--' : '${_bestMs} ms',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: readyColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _start,
                        child: const Text(
                          'Start',
                          style: TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE8B3),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: _reset,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
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

class _StatChip extends StatelessWidget {
  final String title;
  final String value;

  const _StatChip({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ReactionTimeGameScreenState.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ReactionTimeGameScreenState.navy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
