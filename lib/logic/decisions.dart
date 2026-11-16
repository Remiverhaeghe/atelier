/// Aide à la décision : comparer deux ou trois façons de faire sur les mêmes critères.
library;

/// Questions qu'on se pose avant de commencer.
enum Decision { baseboardFixing, parquetLaying, damagedWall }

/// Une façon de faire, notée de 1 (peu) à 3 (beaucoup) sur chaque critère.
enum DecisionOption {
  glueBaseboard(Decision.baseboardFixing, cost: 1, time: 1, difficulty: 1, removable: false),
  nailBaseboard(Decision.baseboardFixing, cost: 1, time: 2, difficulty: 2, removable: true),
  clipBaseboard(Decision.baseboardFixing, cost: 2, time: 2, difficulty: 1, removable: true),
  floatingParquet(Decision.parquetLaying, cost: 1, time: 1, difficulty: 1, removable: true),
  gluedParquet(Decision.parquetLaying, cost: 2, time: 2, difficulty: 2, removable: false),
  nailedParquet(Decision.parquetLaying, cost: 3, time: 3, difficulty: 3, removable: false),
  fillWall(Decision.damagedWall, cost: 1, time: 2, difficulty: 2, removable: false),
  lineWall(Decision.damagedWall, cost: 3, time: 3, difficulty: 2, removable: false);

  const DecisionOption(
    this.decision, {
    required this.cost,
    required this.time,
    required this.difficulty,
    required this.removable,
  });

  final Decision decision;
  final int cost;
  final int time;
  final int difficulty;

  /// Se démonte sans tout casser.
  final bool removable;
}

/// Façons de faire d'une question, dans l'ordre de l'énumération.
List<DecisionOption> optionsFor(Decision pDecision) => [
  for (final vOption in DecisionOption.values)
    if (vOption.decision == pDecision) vOption,
];

/// Option la plus simple : le moins d'effort cumulé (coût, temps, difficulté), à égalité la première.
DecisionOption simplestOption(Decision pDecision) {
  final vOptions = optionsFor(pDecision);
  var rBest = vOptions.first;
  for (final vOption in vOptions.skip(1)) {
    if (vOption.cost + vOption.time + vOption.difficulty <
        rBest.cost + rBest.time + rBest.difficulty) {
      rBest = vOption;
    }
  }

  return rBest;
}
