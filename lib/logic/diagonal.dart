/// Contrôle d'une pièce par sa diagonale : la mesure qui cloche, et les vrais angles.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Écart toléré entre la diagonale du plan et celle mesurée : 2 cm.
const diagonalToleranceMm = 20;

/// Diagonale du coin A au coin C d'après les murs saisis ; null avant trois murs.
double? planDiagonalMm(Room pRoom) {
  if (pRoom.walls.length < 3) {
    return null;
  }
  final vPoints = outline(pRoom);
  final rDiagonal = vPoints[0].distanceTo(vPoints[2]);

  return rDiagonal;
}

/// Écart entre la diagonale mesurée et celle du plan, en millimètres (positif : mesurée plus longue).
double? diagonalGapMm(Room pRoom, int pMeasuredMm) {
  final vPlan = planDiagonalMm(pRoom);
  final rGap = vPlan == null ? null : pMeasuredMm - vPlan;

  return rGap;
}

/// Angle d'un triangle opposé au côté [pOpposite], en degrés ; null si le triangle n'existe pas.
double? _angleDeg(double pSideA, double pSideB, double pOpposite) {
  if (pOpposite >= pSideA + pSideB ||
      pOpposite <= (pSideA - pSideB).abs() ||
      pSideA <= 0 ||
      pSideB <= 0) {
    return null;
  }
  final vCosine = (pSideA * pSideA + pSideB * pSideB - pOpposite * pOpposite) / (2 * pSideA * pSideB);

  return math.acos(vCosine.clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// Angles des quatre coins d'une pièce à quatre murs, déduits des murs et de la diagonale A–C,
/// arrondis au demi-degré, dans l'ordre des murs (angle à la fin de chaque mur : B, C, D, A).
///
/// La diagonale coupe la pièce en deux triangles dont on connaît les trois côtés : leurs angles
/// se calculent par la loi des cosinus. Null pour une autre forme ou des mesures impossibles.
List<double>? anglesFromDiagonal(Room pRoom, int pDiagonalMm) {
  if (pRoom.walls.length != 4 || !pRoom.closed) {
    return null;
  }
  final vAB = pRoom.walls[0].lengthMm.toDouble();
  final vBC = pRoom.walls[1].lengthMm.toDouble();
  final vCD = pRoom.walls[2].lengthMm.toDouble();
  final vDA = pRoom.walls[3].lengthMm.toDouble();
  final vAC = pDiagonalMm.toDouble();
  final vB = _angleDeg(vAB, vBC, vAC);
  final vAInFirst = _angleDeg(vAB, vAC, vBC);
  final vD = _angleDeg(vCD, vDA, vAC);
  final vAInSecond = _angleDeg(vAC, vDA, vCD);
  if (vB == null || vAInFirst == null || vD == null || vAInSecond == null) {
    return null;
  }
  final vC = (180 - vB - vAInFirst) + (180 - vD - vAInSecond);
  final vA = vAInFirst + vAInSecond;
  double vHalf(double pAngle) => (pAngle * 2).round() / 2;
  final rAngles = [vHalf(vB), vHalf(vC), vHalf(vD), vHalf(vA)];

  return rAngles;
}

/// Murs opposés de longueurs différentes dans une pièce saisie d'équerre (4 murs à 90°) :
/// paires de numéros de murs (à partir de 1) et écart, à remesurer ou à corriger par la diagonale.
List<({int first, int second, int gapMm})> oppositeMismatches(Room pRoom) {
  if (pRoom.walls.length != 4 || pRoom.walls.any((pWall) => pWall.angleToNextDeg != 90)) {
    return const [];
  }
  final rPairs = [
    for (final (vFirst, vSecond) in const [(0, 2), (1, 3)])
      if ((pRoom.walls[vFirst].lengthMm - pRoom.walls[vSecond].lengthMm).abs() >
          closureToleranceMm)
        (
          first: vFirst + 1,
          second: vSecond + 1,
          gapMm: (pRoom.walls[vFirst].lengthMm - pRoom.walls[vSecond].lengthMm).abs(),
        ),
  ];

  return rPairs;
}
