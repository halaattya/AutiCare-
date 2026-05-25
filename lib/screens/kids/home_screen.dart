import 'dart:math';
import 'package:flutter/material.dart';

import 'games_screen.dart';
import 'memory_game_screen.dart';
import 'tap_target_game_screen.dart';
import 'sorting_game_screen.dart';
import 'reaction_time_game_screen.dart';
import 'bubble_pop_relax_screen.dart';
import 'child_profile_screen.dart';

import '../parents/parents_screen.dart';

import '../../l10n/app_localizations.dart';

// ✅ ADDED (only for play button logic)
import '../../tracking/daily_log_service.dart';
import '../../tracking/daily_readiness_service.dart';
import '../../tracking/parent_controls_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🎨 Colors
  static const bg = Color(0xFFFFF1C1);
  static const outerPeach = Color(0xFFFFBF80);
  static const innerCream = Color(0xFFFFF1C1);
  static const navy = Color(0xFF24324A);
  static const playBtn = Color(0xFFDDF3F2);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChildProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE9E0FF),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/user_avatar.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: outerPeach,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(200),
                    topRight: Radius.circular(200),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    Text(
                      t.t('hello'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category tiles
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: innerCream,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  label: t.t('communication'),
                                  iconPath: 'assets/icons/communication.png',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GamesScreen(category: 'communication'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  label: t.t('cognitive'),
                                  iconPath: 'assets/icons/cognitive.png',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GamesScreen(category: 'cognitive'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _CategoryCard(
                                  label: t.t('attention'),
                                  iconPath: 'assets/icons/attention.png',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GamesScreen(category: 'attention'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _CategoryCard(
                                  label: t.t('calm_corner'),
                                  iconPath: 'assets/icons/calm_corner.png',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GamesScreen(category: 'calm'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ▶ Play random game
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: playBtn,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),

                      // ✅ ONLY CHANGED THIS PART (onPressed BODY)
                      onPressed: () async {
                        final random = Random();

                        // Keep your original list exactly
                        final gameBuilders = [
                          (BuildContext ctx) => const MemoryGameScreen(),
                          (BuildContext ctx) => const SortingGameScreen(),
                          (BuildContext ctx) => const TapTargetGameScreen(),
                          (BuildContext ctx) => const ReactionTimeGameScreen(),
                          (BuildContext ctx) => const BubblePopRelaxScreen(),
                        ];

                        // 1) Parent option: keep random
                        final keepRandom = await ParentControlsService.getKeepRandomPlay();
                        if (keepRandom) {
                          final index = random.nextInt(gameBuilders.length);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => gameBuilders[index](ctx)),
                          );
                          return;
                        }

                        // 2) If no Daily Log today => RANDOM (as you requested)
                        final todayLog = await DailyLogService.getLogForDate(DateTime.now());
                        if (todayLog == null) {
                          final index = random.nextInt(gameBuilders.length);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => gameBuilders[index](ctx)),
                          );
                          return;
                        }

                        // 3) Smart choice based on readiness
                        final readiness = DailyReadinessService.compute(todayLog);

                        // Low readiness => calming
                        if (readiness.level == ReadinessLevel.low) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BubblePopRelaxScreen()),
                          );
                          return;
                        }

                        // Medium => familiar (memory/sorting)
                        if (readiness.level == ReadinessLevel.medium) {
                          final mediumBuilders = [
                            (BuildContext ctx) => const MemoryGameScreen(),
                            (BuildContext ctx) => const SortingGameScreen(),
                          ];
                          final index = random.nextInt(mediumBuilders.length);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => mediumBuilders[index](ctx)),
                          );
                          return;
                        }

                        // High => challenge (memory/sorting/tap/reaction)
                        final highBuilders = [
                          (BuildContext ctx) => const MemoryGameScreen(),
                          (BuildContext ctx) => const SortingGameScreen(),
                          (BuildContext ctx) => const TapTargetGameScreen(),
                          (BuildContext ctx) => const ReactionTimeGameScreen(),
                        ];
                        final index = random.nextInt(highBuilders.length);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => highBuilders[index](ctx)),
                        );
                      },

                      child: Text(
                        t.t('play'),
                        style: const TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            Container(
              height: 94,
              color: bg,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _BottomNavItem(
                    label: t.t('nav_home'),
                    iconPath: 'assets/icons/home_icon.png',
                    isSelected: true,
                    onTap: () {},
                  ),
                  _BottomNavItem(
                    label: t.t('nav_games'),
                    iconPath: 'assets/icons/games_icon.png',
                    isSelected: false,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesScreen()));
                    },
                  ),
                  _BottomNavItem(
                    label: t.t('nav_parents'),
                    iconPath: 'assets/icons/parents_icon.png',
                    isSelected: false,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset(iconPath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: HomeScreen.navy,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.iconPath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(iconPath, height: 42, width: 42, fit: BoxFit.contain),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: HomeScreen.navy.withOpacity(isSelected ? 1 : 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
