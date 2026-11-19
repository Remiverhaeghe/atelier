/// Cuisine : triangle d'activité, débit de la hotte selon le volume et implantations possibles
/// selon la taille de la pièce. Repères courants, indicatifs.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Côté du triangle évier, plaque, réfrigérateur : ni trop court pour se croiser, ni trop long
/// pour marcher ; et longueur totale.
const triangleSideMinMm = 1200;
const triangleSideMaxMm = 2700;
const triangleTotalMinMm = 4000;
const triangleTotalMaxMm = 7900;

enum TriangleIssue { sideTooShort, sideTooLong, totalTooShort, totalTooLong }

typedef TriangleCheck = ({int totalMm, List<TriangleIssue> issues});

/// Triangle d'après les trois distances, mesurées de centre à centre.
TriangleCheck checkTriangle(int pSinkToHobMm, int pHobToFridgeMm, int pFridgeToSinkMm) {
  final vSides = [pSinkToHobMm, pHobToFridgeMm, pFridgeToSinkMm];
  final vTotal = vSides.fold(0, (pSum, pSide) => pSum + pSide);
  final rCheck = (
    totalMm: vTotal,
    issues: [
      if (vSides.any((pSide) => pSide < triangleSideMinMm)) TriangleIssue.sideTooShort,
      if (vSides.any((pSide) => pSide > triangleSideMaxMm)) TriangleIssue.sideTooLong,
      if (vTotal < triangleTotalMinMm) TriangleIssue.totalTooShort,
      if (vTotal > triangleTotalMaxMm) TriangleIssue.totalTooLong,
    ],
  );

  return rCheck;
}

/// Une hotte doit renouveler environ dix fois le volume de la cuisine par heure.
const hoodChangesPerHour = 10;

/// Débits vendus, en m³/h.
const hoodFlowsM3h = [300, 400, 500, 600, 700, 800, 900];

typedef HoodNeed = ({int neededM3h, int hoodM3h});

/// Débit nécessaire pour [pVolumeM3], et le premier débit vendu qui suffit.
HoodNeed hoodFor(double pVolumeM3) {
  final vNeeded = (pVolumeM3 * hoodChangesPerHour - 1e-9).ceil();
  final rNeed = (
    neededM3h: math.max(vNeeded, 0),
    hoodM3h: hoodFlowsM3h.firstWhere((pFlow) => pFlow >= vNeeded, orElse: () => hoodFlowsM3h.last),
  );

  return rNeed;
}

/// Profondeur des meubles bas, d'un îlot, et passage confortable devant.
const runDepthMm = 600;
const islandDepthMm = 900;
const aisleMm = 1200;

/// Longueur minimale d'un linéaire pour évier, plaque et réfrigérateur côte à côte.
const minRunMm = 1800;

enum KitchenLayout { linear, parallel, lShape, uShape, island }

/// Implantations qui tiennent dans une pièce de [pWidthMm] sur [pLengthMm] (la plus grande).
List<KitchenLayout> kitchenLayouts(int pWidthMm, int pLengthMm) {
  final vWidth = math.min(pWidthMm, pLengthMm);
  final vLength = math.max(pWidthMm, pLengthMm);
  final vTwoRuns = 2 * runDepthMm + aisleMm;
  final rLayouts = [
    if (vLength >= minRunMm) KitchenLayout.linear,
    if (vWidth >= vTwoRuns && vLength >= minRunMm) KitchenLayout.parallel,
    if (vWidth >= runDepthMm + aisleMm && vLength >= minRunMm) KitchenLayout.lShape,
    if (vWidth >= vTwoRuns && vLength >= vTwoRuns) KitchenLayout.uShape,
    if (vWidth >= runDepthMm + 2 * aisleMm + islandDepthMm && vLength >= 3000) KitchenLayout.island,
  ];

  return rLayouts;
}

/// Largeur et longueur hors tout du contour d'une pièce, la plus petite d'abord.
({int widthMm, int lengthMm}) roomBox(Room pRoom) {
  final vPoints = outline(pRoom);
  final vXs = vPoints.map((pPoint) => pPoint.x);
  final vYs = vPoints.map((pPoint) => pPoint.y);
  final vDx = (vXs.reduce(math.max) - vXs.reduce(math.min)).round();
  final vDy = (vYs.reduce(math.max) - vYs.reduce(math.min)).round();

  return (widthMm: math.min(vDx, vDy), lengthMm: math.max(vDx, vDy));
}
