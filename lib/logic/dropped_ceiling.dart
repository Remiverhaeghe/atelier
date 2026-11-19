/// Faux plafond : abaisser un plafond trop haut avec des plaques de plâtre vissées sur des
/// fourrures métalliques, elles-mêmes pendues au plafond existant par des suspentes.
///
/// Les fourrures suivent la grande longueur ; leurs deux bords reposent sur une cornière vissée
/// au mur. Entre le vieux plafond et le nouveau reste un vide, le plénum, où passent l'isolant
/// et les gaines.
library;

import 'dart:math' as math;

import 'insulation.dart';

/// Hauteur sous plafond minimale d'un logement décent.
const minLivingHeightMm = 2200;

/// Épaisseur de la plaque de plâtre et de la fourrure sous laquelle elle est vissée.
const ceilingBoardMm = 13;
const furringDepthMm = 27;

/// Fourrures et cornières vendues en 3 m, plaques de 1,20 × 2,50 m.
const ceilingBarMm = 3000;
const ceilingBoardM2 = 3.0;

/// Chutes de plaques, et vis à plaque pour un mètre carré de plafond.
const ceilingBoardWaste = 0.1;
const ceilingScrewsPerM2 = 15;

/// Plénum jusqu'auquel une suspente réglable seule suffit ; au-delà, une tige filetée.
const directHangerMaxMm = 120;

/// Plénum au-delà duquel l'ossature doit être contreventée.
const bracedPlenumMm = 1000;

/// Tiges filetées vendues au mètre.
const rodLengthMm = 1000;

/// Comment pendre les fourrures, selon la hauteur du plénum.
enum Hanging { direct, rod, braced }

typedef CeilingPlan = ({
  int plenumMm,
  Hanging hanging,
  int rows,
  int furringBars,
  int joints,
  int hangers,
  int rods,
  int angleBars,
  int boards,
  int screws,
  double savedVolumeM3,
  bool tooLow,
});

/// Plafond de [pLengthMm] × [pWidthMm], aujourd'hui à [pHeightMm], abaissé à [pWantedMm].
CeilingPlan planDroppedCeiling({
  required int pLengthMm,
  required int pWidthMm,
  required int pHeightMm,
  required int pWantedMm,
}) {
  final vLong = math.max(math.max(pLengthMm, pWidthMm), 0);
  final vShort = math.max(math.min(pLengthMm, pWidthMm), 0);
  final vPlenum = math.max(pHeightMm - pWantedMm - ceilingBoardMm - furringDepthMm, 0);
  final vHanging = vPlenum <= directHangerMaxMm
      ? Hanging.direct
      : vPlenum <= bracedPlenumMm
      ? Hanging.rod
      : Hanging.braced;
  // Les bords reposent sur la cornière : seules les fourrures du milieu sont pendues
  final vRows = vShort == 0 ? 0 : math.max((vShort / furringSpacingMm).ceil() - 1, 1);
  final vBarsPerRow = (vLong / ceilingBarMm).ceil();
  final vHangersPerRow = vLong == 0 ? 0 : math.max((vLong / hangerSpacingMm).ceil(), 2);
  final vHangers = vRows * vHangersPerRow;
  final vAreaM2 = vLong * vShort / 1e6;
  final rPlan = (
    plenumMm: vPlenum,
    hanging: vHanging,
    rows: vRows,
    furringBars: vRows * vBarsPerRow,
    joints: vRows * math.max(vBarsPerRow - 1, 0),
    hangers: vHangers,
    // Une tige par suspente, coupée dans des tiges d'un mètre
    rods: vHanging == Hanging.direct ? 0 : vHangers * (vPlenum / rodLengthMm).ceil(),
    angleBars: (2 * (vLong + vShort) / ceilingBarMm).ceil(),
    boards: (vAreaM2 * (1 + ceilingBoardWaste) / ceilingBoardM2 - 1e-9).ceil(),
    screws: (vAreaM2 * ceilingScrewsPerM2).ceil(),
    savedVolumeM3: vAreaM2 * math.max(pHeightMm - pWantedMm, 0) / 1000,
    tooLow: pWantedMm < minLivingHeightMm,
  );

  return rPlan;
}
