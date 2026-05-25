import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../tracking/active_child_provider.dart';

import 'memory_game_screen.dart';
import 'sorting_game_screen.dart';
import 'match_game_screen.dart';
import 'tap_target_game_screen.dart';
import 'reaction_time_game_screen.dart';
import 'bubble_pop_relax_screen.dart';
import 'communication_game_screen.dart';

import '../../l10n/app_localizations.dart';

class GamesScreen extends StatelessWidget {
  final String? category;

  const GamesScreen({super.key, this.category});

  static const background = Color(0xFFFFF7ED);
  static const outerCard = Color(0xFFF2D1B3);
  static const innerCard = Color(0xFFFFF2DA);

  static const tileMint = Color(0xFFDDF3F2);
  static const tileButter = Color(0xFFFFE8B3);
  static const tilePeach = Color(0xFFF6D1B6);
  static const tileLilac = Color(0xFFE9E0FF);

  static const navyText = Color(0xFF1F2A44);

  static const String kMemory = 'memory';
  static const String kMatch = 'match';
  static const String kTap = 'tap';
  static const String kComm = 'comm';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return FutureBuilder<String?>(
      future: ActiveChildProvider.getActiveChildId(),
      builder: (context, childSnap) {
        final childId = childSnap.data;

        if (childId == null) {
          return _buildBody(context, t, const {});
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('children')
              .doc(childId)
              .snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data();
            final pc =
                (data?['parentControls'] as Map?)?.cast<String, dynamic>() ?? {};
            final hidden =
                (pc['hiddenGames'] as Map?)?.cast<String, dynamic>() ?? {};

            return _buildBody(context, t, {
              kMemory: hidden[kMemory] == true,
              kMatch: hidden[kMatch] == true,
              kTap: hidden[kTap] == true,
              kComm: hidden[kComm] == true,
            }, childId);
          },
        );
      },
    );
  }

  Scaffold _buildBody(
    BuildContext context,
    AppLocalizations t,
    Map<String, bool> hide, [
    String? childId,
  ]) {
    bool isHidden(String key) => hide[key] == true;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.t('games'),
          style: const TextStyle(
            color: navyText,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: outerCard,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: innerCard,
              borderRadius: BorderRadius.circular(26),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category == null || category == 'communication') ...[
                    SectionTitle(title: t.t('sec_comm_games')),

                    if (!isHidden(kComm))
                      GameButton(
                        title: 'Match Face Expression',
                        color: tileButter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CommunicationGameScreen(childId: childId),
                            ),
                          );
                        },
                      ),

                    GameButton(
                      title: t.t('matching_pictures'),
                      color: tileButter,
                      onTap: () => _comingSoon(context, t),
                    ),
                    GameButton(
                      title: t.t('sound_matching'),
                      color: tileMint,
                      onTap: () => _comingSoon(context, t),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (category == null || category == 'cognitive') ...[
                    SectionTitle(title: t.t('sec_cog_games')),

                    if (!isHidden(kMemory))
                      GameButton(
                        title: t.t('memory_game'),
                        color: tileButter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MemoryGameScreen()),
                          );
                        },
                      ),

                    GameButton(
                      title: t.t('sorting_game'),
                      color: tilePeach,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SortingGameScreen()),
                        );
                      },
                    ),

                    if (!isHidden(kMatch))
                      GameButton(
                        title: t.t('shape_matching'),
                        color: tileLilac,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const MatchGameScreen()),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                  ],

                  if (category == null || category == 'attention') ...[
                    SectionTitle(title: t.t('sec_attention')),

                    if (!isHidden(kTap))
                      GameButton(
                        title: t.t('tap_target'),
                        color: tileMint,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TapTargetGameScreen()),
                          );
                        },
                      ),

                    GameButton(
                      title: t.t('find_object'),
                      color: tilePeach,
                      onTap: () => _comingSoon(context, t),
                    ),
                    GameButton(
                      title: t.t('pop_balloon'),
                      color: tileLilac,
                      onTap: () => _comingSoon(context, t),
                    ),
                    GameButton(
                      title: t.t('reaction_time'),
                      color: tileButter,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ReactionTimeGameScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (category == null || category == 'calm') ...[
                    SectionTitle(title: t.t('sec_calm')),
                    GameButton(
                      title: t.t('breathing'),
                      color: tilePeach,
                      onTap: () => _comingSoon(context, t),
                    ),
                    GameButton(
                      title: t.t('calming_sounds'),
                      color: tileButter,
                      onTap: () => _comingSoon(context, t),
                    ),
                    GameButton(
                      title: t.t('bubble_pop'),
                      color: tileMint,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const BubblePopRelaxScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, AppLocalizations t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.t('coming_soon')),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: GamesScreen.navyText,
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  final String title;
  final Color color;
  final VoidCallback onTap;

  const GameButton({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.sports_esports,
                    color: GamesScreen.navyText),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: GamesScreen.navyText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
