import 'game_ids.dart';

class GameDefinition {
  final String title;
  final String primaryMetricKey;
  final bool primaryHigherIsBetter;

  final String? secondaryMetricKey;
  final bool secondaryHigherIsBetter;

  const GameDefinition({
    required this.title,
    required this.primaryMetricKey,
    required this.primaryHigherIsBetter,
    this.secondaryMetricKey,
    this.secondaryHigherIsBetter = true,
  });
}

class GameDefinitions {
  static const Map<String, GameDefinition> defs = {
    GameIds.memory: GameDefinition(
      title: 'Memory Game',
      primaryMetricKey: 'score',
      primaryHigherIsBetter: true,
      secondaryMetricKey: 'accuracy',
      secondaryHigherIsBetter: true,
    ),

    GameIds.shapeMatching: GameDefinition(
      title: 'Shape Matching',
      primaryMetricKey: 'accuracy',
      primaryHigherIsBetter: true,
      secondaryMetricKey: 'avgTimeMs',
      secondaryHigherIsBetter: false, // lower is better
    ),

    GameIds.tapTarget: GameDefinition(
      title: 'Tap the Target',
      primaryMetricKey: 'accuracy',
      primaryHigherIsBetter: true,
      secondaryMetricKey: 'hitsPerMin',
      secondaryHigherIsBetter: true,
    ),

    // ✅ New Communication Game
    GameIds.communication: GameDefinition(
      title: 'Communication Game',
      primaryMetricKey: 'successfulResponses',
      primaryHigherIsBetter: true,
      secondaryMetricKey: 'promptLevel',
      secondaryHigherIsBetter: false, // lower prompts = better communication
    ),
  };

  static GameDefinition forId(String gameId) {
    return defs[gameId] ??
        GameDefinition(
          title: gameId,
          primaryMetricKey: 'accuracy',
          primaryHigherIsBetter: true,
        );
  }
}
