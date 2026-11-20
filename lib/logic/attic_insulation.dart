/// Isoler les rampants par l'intérieur : l'isolant mange de la hauteur, donc de la surface où
/// l'on tient debout.
///
/// L'isolant posé sous le rampant le décale vers la pièce de son épaisseur, mesurée
/// perpendiculairement : à la verticale, le plafond descend de e / cos(pente). Celui posé contre
/// la jambette la rapproche du milieu de la pièce.
library;

import 'dart:math' as math;

import 'attic_section.dart';

/// Conductivité d'une laine minérale courante, en W/m·K.
const defaultLambda = 0.035;

typedef AtticInsulation = ({
  AtticSection after,
  double usableBeforeM2,
  double usableAfterM2,
  double lostM2,
  int lostPercent,
  double rValue,
});

/// Pièce de [pWidthMm] × [pLengthMm] sous rampants, isolée de [pSlopeInsulationMm] sous les
/// rampants et de [pKneeInsulationMm] contre les jambettes.
AtticInsulation insulateAttic({
  required int pWidthMm,
  required int pLengthMm,
  required int pKneeWallMm,
  required double pSlopeDeg,
  required bool pTwoPitches,
  required int pSlopeInsulationMm,
  required int pKneeInsulationMm,
  int? pCeilingMm,
  double pLambda = defaultLambda,
}) {
  final vSlope = pSlopeDeg.clamp(1.0, 89.0) * math.pi / 180;
  final vSides = pTwoPitches ? 2 : 1;
  final vSlopeIns = math.max(0, pSlopeInsulationMm);
  final vKneeIns = math.max(0, pKneeInsulationMm);
  final vBefore = atticSection(
    pWidthMm: pWidthMm,
    pKneeWallMm: pKneeWallMm,
    pSlopeDeg: pSlopeDeg,
    pTwoPitches: pTwoPitches,
    pCeilingMm: pCeilingMm,
  );
  // Au nouveau pied de mur, le rampant est plus haut ; l'isolant le fait redescendre
  final vKnee = pKneeWallMm + vKneeIns * math.tan(vSlope) - vSlopeIns / math.cos(vSlope);
  final vAfter = atticSection(
    pWidthMm: math.max(0, pWidthMm - vSides * vKneeIns),
    pKneeWallMm: math.max(0, vKnee.round()),
    pSlopeDeg: pSlopeDeg,
    pTwoPitches: pTwoPitches,
    pCeilingMm: pCeilingMm == null ? null : pCeilingMm - vSlopeIns,
  );
  final vLength = math.max(0, pLengthMm) / 1000;
  final vBeforeM2 = vBefore.usableWidthMm / 1000 * vLength;
  final vAfterM2 = vAfter.usableWidthMm / 1000 * vLength;
  final vLost = math.max(0.0, vBeforeM2 - vAfterM2);
  final rInsulation = (
    after: vAfter,
    usableBeforeM2: vBeforeM2,
    usableAfterM2: vAfterM2,
    lostM2: vLost,
    lostPercent: vBeforeM2 <= 0 ? 0 : (100 * vLost / vBeforeM2).round(),
    rValue: vSlopeIns / 1000 / pLambda,
  );

  return rInsulation;
}
