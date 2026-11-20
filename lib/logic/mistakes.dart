/// « Je me suis trompé » : les ratés courants, leur cause, la réparation et ce qu'on peut
/// réutiliser.
library;

import 'gestures.dart';

/// Ce que devient la pièce ratée.
enum MistakeOutcome {
  /// Elle se répare sur place et reste à sa place.
  repair,

  /// Elle ne sert plus là, mais se recoupe pour une pièce plus petite.
  reuse,
}

/// Ratés courants. [gesture] : le geste à revoir pour ne pas recommencer. [waitHours] : attente
/// avant de pouvoir réparer (séchage). [steps] : nombre d'étapes de réparation dans les textes.
enum Mistake {
  looseTenon(gesture: Gesture.chisel, outcome: MistakeOutcome.repair, waitHours: 0, steps: 3),
  warpedBoard(gesture: Gesture.plane, outcome: MistakeOutcome.reuse, waitHours: 48, steps: 3),
  misplacedHole(gesture: Gesture.drill, outcome: MistakeOutcome.repair, waitHours: 2, steps: 3),
  varnishRun(gesture: Gesture.sand, outcome: MistakeOutcome.repair, waitHours: 24, steps: 3),
  failedSealant(gesture: Gesture.caulk, outcome: MistakeOutcome.repair, waitHours: 0, steps: 3),
  shortCut(gesture: Gesture.saw, outcome: MistakeOutcome.reuse, waitHours: 0, steps: 3);

  const Mistake({
    required this.gesture,
    required this.outcome,
    required this.waitHours,
    required this.steps,
  });

  final Gesture gesture;
  final MistakeOutcome outcome;
  final int waitHours;
  final int steps;
}

/// Ratés qui viennent du geste [pGesture], pour les rappeler sous ce geste.
List<Mistake> mistakesFor(Gesture pGesture) =>
    Mistake.values.where((pMistake) => pMistake.gesture == pGesture).toList();

/// Quand on peut reprendre un raté constaté à [pNow].
DateTime repairFrom(Mistake pMistake, DateTime pNow) =>
    pNow.add(Duration(hours: pMistake.waitHours));
