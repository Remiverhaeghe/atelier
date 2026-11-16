/// Plan papier décalqué : une cote connue donne l'échelle, les coins touchés sur la photo
/// donnent les murs.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Millimètres réels par point d'écran, d'après deux points d'une cote connue.
double traceScale(PlanPoint pStart, PlanPoint pEnd, int pKnownMm) {
  final vPixels = pStart.distanceTo(pEnd);

  return vPixels <= 0 ? 0 : pKnownMm / vPixels;
}

/// Écart sous lequel un angle tracé à main levée est ramené au multiple de 45° le plus proche.
const snapDeg = 4.0;

double _snap(double pDeg) {
  final vNearest = (pDeg / 45).round() * 45.0;

  return (pDeg - vNearest).abs() <= snapDeg ? vNearest : pDeg;
}

/// Surface signée, positive quand le tour se fait dans le sens inverse des aiguilles d'une
/// montre, avec y vers le haut.
double _signedArea(List<PlanPoint> pPoints) {
  var vSum = 0.0;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    vSum += vA.x * vB.y - vB.x * vA.y;
  }

  return vSum / 2;
}

/// Murs d'une pièce fermée dont les coins ont été touchés sur l'écran, dans l'ordre du tour.
///
/// L'écran a son axe y vers le bas : il est retourné, puis le tour est remis dans le sens
/// attendu par le plan. Les longueurs sont arrondies au centimètre, les angles presque droits
/// ramenés à 90°.
List<Wall> wallsFromCorners(List<PlanPoint> pScreen, double pScale) {
  if (pScreen.length < 3 || pScale <= 0) {
    return const [];
  }
  var vPoints = [for (final vPoint in pScreen) PlanPoint(vPoint.x * pScale, -vPoint.y * pScale)];
  if (_signedArea(vPoints) < 0) {
    vPoints = vPoints.reversed.toList();
  }
  final vCount = vPoints.length;
  double vHeading(int pIndex) {
    final vA = vPoints[pIndex % vCount];
    final vB = vPoints[(pIndex + 1) % vCount];

    return math.atan2(vB.y - vA.y, vB.x - vA.x);
  }

  final rWalls = <Wall>[];
  for (var vIndex = 0; vIndex < vCount; vIndex++) {
    final vLength = vPoints[vIndex].distanceTo(vPoints[(vIndex + 1) % vCount]);
    var vTurn = vHeading(vIndex + 1) - vHeading(vIndex);
    while (vTurn > math.pi) {
      vTurn -= 2 * math.pi;
    }
    while (vTurn <= -math.pi) {
      vTurn += 2 * math.pi;
    }
    rWalls.add(
      Wall(
        lengthMm: (vLength / 10).round() * 10,
        angleToNextDeg: _snap(180 - vTurn * 180 / math.pi),
      ),
    );
  }

  return rWalls;
}
