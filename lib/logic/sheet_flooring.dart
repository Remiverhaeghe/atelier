/// Sol souple en rouleau (vinyle, lino, moquette) : lés, longueur à commander, colle.
library;

import 'geometry.dart';
import 'room.dart';

/// Largeurs de rouleau courantes, en millimètres.
const rollWidthsMm = [2000, 3000, 4000, 5000];

/// Marge de recoupe à chaque bout d'un lé, contre un mur jamais droit.
const sheetTrimMm = 50;

/// Colle acrylique pour sol souple : environ 300 g par mètre carré.
const sheetGlueKgPerM2 = 0.3;

/// Rectangle qui contient la pièce : on commande des lés pour lui, pas pour le contour exact.
({int lengthMm, int widthMm}) roomBox(Room pRoom) {
  final vPoints = outline(pRoom);
  if (vPoints.isEmpty) {
    return (lengthMm: 0, widthMm: 0);
  }
  double vSpan(double Function(PlanPoint) pAxis) {
    final vValues = vPoints.map(pAxis);

    final vMax = vValues.reduce((pA, pB) => pA > pB ? pA : pB);
    final vMin = vValues.reduce((pA, pB) => pA < pB ? pA : pB);

    return vMax - vMin;
  }

  final rBox = (
    lengthMm: vSpan((pPoint) => pPoint.x).round(),
    widthMm: vSpan((pPoint) => pPoint.y).round(),
  );

  return rBox;
}

typedef SheetPlan = ({
  int strips,
  int stripMm,
  int totalMm,
  bool alongLength,
  int seams,
  double areaM2,
});

/// Lés posés dans un sens : chacun fait la longueur de la pièce plus les recoupes, arrondie au
/// raccord du motif.
SheetPlan _strips(int pAlongMm, int pAcrossMm, int pRollMm, int pRepeatMm, bool pAlongLength) {
  final vStrips = pAcrossMm <= 0 ? 0 : (pAcrossMm / pRollMm - 1e-9).ceil();
  var vStrip = pAlongMm + 2 * sheetTrimMm;
  if (pRepeatMm > 0 && vStrips > 1) {
    vStrip = (vStrip / pRepeatMm - 1e-9).ceil() * pRepeatMm;
  }
  final vTotal = vStrips * vStrip;

  return (
    strips: vStrips,
    stripMm: vStrip,
    totalMm: vTotal,
    alongLength: pAlongLength,
    seams: vStrips > 0 ? vStrips - 1 : 0,
    areaM2: vTotal * pRollMm / 1e6,
  );
}

/// Sens qui demande le moins de rouleau ; à longueur égale, celui qui fait le moins de joints.
SheetPlan planSheet(int pLengthMm, int pWidthMm, int pRollMm, {int pRepeatMm = 0}) {
  final vAlong = _strips(pLengthMm, pWidthMm, pRollMm, pRepeatMm, true);
  final vAcross = _strips(pWidthMm, pLengthMm, pRollMm, pRepeatMm, false);
  if (vAlong.totalMm != vAcross.totalMm) {
    return vAlong.totalMm < vAcross.totalMm ? vAlong : vAcross;
  }

  return vAlong.seams <= vAcross.seams ? vAlong : vAcross;
}

double sheetGlueKg(double pFloorM2) => pFloorM2 * sheetGlueKgPerM2;
