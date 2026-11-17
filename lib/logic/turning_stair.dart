/// Escalier quart tournant ou demi-tournant : la ligne de foulée garde le giron de
/// l'escalier droit et passe au milieu de l'emmarchement dans le tournant.
///
/// Les marches du tournant sont balancées : elles rétrécissent côté intérieur, et quelques
/// marches avant et après sont décalées pour adoucir le passage. Le traçage exact se fait
/// à l'épure, sur place.
library;

import 'dart:math' as math;

import 'fixtures.dart';

enum StairShape { straight, quarterTurn, halfTurn }

/// Marches décalées de chaque côté du tournant pour le balancement.
const balancingEachSide = 2;

typedef TurningStair = ({
  StairShape shape,
  StairPlan plan,

  /// Longueur de la ligne de foulée : marches fois giron.
  int walkingLineMm,

  /// Volées droites avant et après le tournant, sur la ligne de foulée.
  int firstFlightMm,
  int secondFlightMm,

  /// Emprise au sol : longueur et largeur du rectangle occupé.
  int footprintLengthMm,
  int footprintWidthMm,

  /// Marches dans le tournant, et marches balancées en tout.
  int turningTreads,
  int balancedTreads,
});

/// Escalier de [pWidthMm] d'emmarchement pour monter [pRiseMm], de forme [pShape].
TurningStair designTurningStair(int pRiseMm, StairShape pShape, {int pWidthMm = 800}) {
  final vPlan = stairPlan(pRiseMm);
  final vTreads = math.max(vPlan.risers - 1, 0);
  final vWalking = vTreads * vPlan.goingMm;
  // Ligne de foulée au milieu de l'emmarchement : un quart ou un demi-cercle de rayon w / 2
  final vArc = switch (pShape) {
    StairShape.straight => 0.0,
    StairShape.quarterTurn => math.pi * pWidthMm / 4,
    StairShape.halfTurn => math.pi * pWidthMm / 2,
  };
  final vTurning = vPlan.goingMm <= 0 ? 0 : (vArc / vPlan.goingMm).round();
  final vStraightTreads = math.max(vTreads - vTurning, 0);
  final vFirst = (vStraightTreads ~/ 2) * vPlan.goingMm;
  final vSecond = (vStraightTreads - vStraightTreads ~/ 2) * vPlan.goingMm;
  final rStair = (
    shape: pShape,
    plan: vPlan,
    walkingLineMm: vWalking,
    firstFlightMm: pShape == StairShape.straight ? vWalking : vFirst,
    secondFlightMm: pShape == StairShape.straight ? 0 : vSecond,
    footprintLengthMm: switch (pShape) {
      StairShape.straight => vWalking,
      StairShape.quarterTurn => vFirst + pWidthMm,
      StairShape.halfTurn => math.max(vFirst, vSecond) + pWidthMm,
    },
    footprintWidthMm: switch (pShape) {
      StairShape.straight => pWidthMm,
      StairShape.quarterTurn => vSecond + pWidthMm,
      StairShape.halfTurn => 2 * pWidthMm,
    },
    turningTreads: vTurning,
    balancedTreads: vTurning == 0 ? 0 : math.min(vTreads, vTurning + 2 * balancingEachSide),
  );

  return rStair;
}
