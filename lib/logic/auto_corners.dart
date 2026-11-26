/// Angles des coins déduits des seules longueurs : rien n'est droit chez soi, et on ne mesure que les murs.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Angle d'un triangle opposé au côté [pOpposite], en degrés ; null si le triangle n'existe pas.
double? _angleDeg(double pSideA, double pSideB, double pOpposite) {
  if (pSideA <= 0 || pSideB <= 0 || pOpposite >= pSideA + pSideB) {
    return null;
  }
  if (pOpposite <= (pSideA - pSideB).abs()) {
    return null;
  }
  final vCosine =
      (pSideA * pSideA + pSideB * pSideB - pOpposite * pOpposite) / (2 * pSideA * pSideB);

  return math.acos(vCosine.clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// Quatre angles (fin des murs 1 à 4) pour une diagonale A–C donnée, ou null si elle est impossible.
List<double>? _anglesFor(List<double> pSides, double pDiagonal) {
  final vAB = pSides[0], vBC = pSides[1], vCD = pSides[2], vDA = pSides[3];
  final vB = _angleDeg(vAB, vBC, pDiagonal);
  final vAFirst = _angleDeg(vAB, pDiagonal, vBC);
  final vCFirst = _angleDeg(vBC, pDiagonal, vAB);
  final vD = _angleDeg(vCD, vDA, pDiagonal);
  final vASecond = _angleDeg(pDiagonal, vDA, vCD);
  final vCSecond = _angleDeg(vCD, pDiagonal, vDA);
  if (vB == null ||
      vAFirst == null ||
      vCFirst == null ||
      vD == null ||
      vASecond == null ||
      vCSecond == null) {
    return null;
  }

  return [vB, vCFirst + vCSecond, vD, vAFirst + vASecond];
}

double _spread(List<double> pAngles) =>
    pAngles.fold(0.0, (pSum, pAngle) => pSum + (pAngle - 90) * (pAngle - 90));

/// Angles des coins d'une pièce à quatre murs, dans l'ordre des murs (fin du mur 1, 2, 3, 4),
/// les plus proches possible de 90° tout en refermant le contour. Quatre longueurs laissent un
/// degré de liberté (la forme peut « pencher ») : on prend la forme la plus proche d'un rectangle.
///
/// Null s'il n'y a pas quatre longueurs, ou si elles ne forment aucun quadrilatère.
List<double>? bestFitCorners(List<int> pLengthsMm) {
  if (pLengthsMm.length != 4 || pLengthsMm.any((pLength) => pLength <= 0)) {
    return null;
  }
  final vSides = [for (final vLength in pLengthsMm) vLength.toDouble()];
  final vLow = math.max((vSides[0] - vSides[1]).abs(), (vSides[2] - vSides[3]).abs());
  final vHigh = math.min(vSides[0] + vSides[1], vSides[2] + vSides[3]);
  if (vLow >= vHigh) {
    return null;
  }
  const vSteps = 2000;
  List<double>? rBest;
  var vBestSpread = double.infinity;
  var vBestDiagonal = vLow;
  for (var vStep = 1; vStep < vSteps; vStep++) {
    final vDiagonal = vLow + (vHigh - vLow) * vStep / vSteps;
    final vAngles = _anglesFor(vSides, vDiagonal);
    if (vAngles != null && _spread(vAngles) < vBestSpread) {
      rBest = vAngles;
      vBestSpread = _spread(vAngles);
      vBestDiagonal = vDiagonal;
    }
  }
  // Second passage, resserré autour du meilleur pas
  final vWidth = (vHigh - vLow) / vSteps;
  for (var vStep = 0; vStep <= 200; vStep++) {
    final vDiagonal = vBestDiagonal - vWidth + 2 * vWidth * vStep / 200;
    final vAngles = _anglesFor(vSides, vDiagonal);
    if (vAngles != null && _spread(vAngles) < vBestSpread) {
      rBest = vAngles;
      vBestSpread = _spread(vAngles);
    }
  }

  return rBest;
}

/// Murs dont les angles sont ajustés pour que la pièce se ferme, quand c'est utile : quatre murs,
/// tous les coins laissés à 90° (rien de saisi à la main) et un contour qui ne se referme pas.
/// Les autres cas sont rendus tels quels.
List<Wall> withFittedCorners(List<Wall> pWalls) {
  if (pWalls.length != 4 || pWalls.any((pWall) => pWall.angleToNextDeg != 90)) {
    return pWalls;
  }
  final vSquare = Room(id: '', name: '', walls: pWalls, closed: true);
  if (closesProperly(vSquare)) {
    return pWalls;
  }
  final vAngles = bestFitCorners([for (final vWall in pWalls) vWall.lengthMm]);
  if (vAngles == null) {
    return pWalls;
  }

  return [
    for (final (vIndex, vWall) in pWalls.indexed) vWall.copyWith(angleToNextDeg: vAngles[vIndex]),
  ];
}
