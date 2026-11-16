/// Plafond rampant : un pan de toit qui descend vers un mur de la pièce.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Pente du plafond : basse le long du mur [wallIndex] (hauteur [lowMm]), elle remonte jusqu'à la
/// hauteur sous plafond sur [runMm] mesurés au sol, perpendiculairement au mur.
class Slope {
  const Slope({required this.wallIndex, required this.lowMm, required this.runMm});

  final int wallIndex;

  /// Hauteur du mur bas (jambette), du sol au plafond.
  final int lowMm;

  /// Largeur au sol de la partie en pente.
  final int runMm;

  Map<String, Object?> toJson() => {'wallIndex': wallIndex, 'lowMm': lowMm, 'runMm': runMm};

  static Slope fromJson(Map<String, Object?> pJson) => Slope(
    wallIndex: pJson['wallIndex']! as int,
    lowMm: pJson['lowMm']! as int,
    runMm: pJson['runMm']! as int,
  );
}

/// Pente utilisable : un mur qui existe, une jambette plus basse que le plafond, une largeur.
Slope? activeSlope(Room pRoom) {
  final vSlope = pRoom.slope;
  if (vSlope == null ||
      vSlope.wallIndex >= pRoom.walls.length ||
      vSlope.runMm <= 0 ||
      vSlope.lowMm >= pRoom.ceilingHeightMm) {
    return null;
  }

  return vSlope;
}

/// Distance d'un point au mur bas, comptée vers l'intérieur de la pièce.
double _depthFromLowWall(Room pRoom, Slope pSlope, PlanPoint pPoint) {
  final vPoints = outline(pRoom);
  final vStart = vPoints[pSlope.wallIndex];
  final vEnd = vPoints[pSlope.wallIndex + 1];
  final vLength = math.max(vStart.distanceTo(vEnd), 1);
  // Murs dans le sens inverse des aiguilles d'une montre : l'intérieur est à gauche
  final vNormalX = -(vEnd.y - vStart.y) / vLength;
  final vNormalY = (vEnd.x - vStart.x) / vLength;
  final rDepth = (pPoint.x - vStart.x) * vNormalX + (pPoint.y - vStart.y) * vNormalY;

  return rDepth;
}

/// Hauteur sous plafond à un endroit de la pièce.
double ceilingHeightAt(Room pRoom, PlanPoint pPoint) {
  final vSlope = activeSlope(pRoom);
  if (vSlope == null) {
    return pRoom.ceilingHeightMm.toDouble();
  }
  final vShare = (_depthFromLowWall(pRoom, vSlope, pPoint) / vSlope.runMm).clamp(0.0, 1.0);
  final rHeight = vSlope.lowMm + (pRoom.ceilingHeightMm - vSlope.lowMm) * vShare;

  return rHeight;
}

/// Surface d'un mur, du sol au plafond, pente comprise (portes et fenêtres non retirées).
double wallAreaMm2(Room pRoom, int pWallIndex) {
  final vLength = pRoom.walls[pWallIndex].lengthMm.toDouble();
  if (activeSlope(pRoom) == null) {
    return vLength * pRoom.ceilingHeightMm;
  }
  final vPoints = outline(pRoom);
  final vStart = vPoints[pWallIndex];
  final vEnd = vPoints[pWallIndex + 1];
  // Hauteur linéaire par morceaux le long du mur : des trapèzes fins suffisent
  const vSteps = 200;
  var rArea = 0.0;
  var vPrevious = ceilingHeightAt(pRoom, vStart);
  for (var vStep = 1; vStep <= vSteps; vStep++) {
    final vShare = vStep / vSteps;
    final vHeight = ceilingHeightAt(
      pRoom,
      PlanPoint(vStart.x + (vEnd.x - vStart.x) * vShare, vStart.y + (vEnd.y - vStart.y) * vShare),
    );
    rArea += (vPrevious + vHeight) / 2 * vLength / vSteps;
    vPrevious = vHeight;
  }

  return rArea;
}

/// Polygone coupé par le demi-plan des points à moins de [pDepthMm] du mur bas.
List<PlanPoint> _band(Room pRoom, Slope pSlope, double pDepthMm) {
  final vPoints = outline(pRoom).take(pRoom.walls.length).toList();
  final rBand = <PlanPoint>[];
  for (var vIndex = 0; vIndex < vPoints.length; vIndex++) {
    final vA = vPoints[vIndex];
    final vB = vPoints[(vIndex + 1) % vPoints.length];
    final vDepthA = _depthFromLowWall(pRoom, pSlope, vA) - pDepthMm;
    final vDepthB = _depthFromLowWall(pRoom, pSlope, vB) - pDepthMm;
    if (vDepthA <= 0) {
      rBand.add(vA);
    }
    if ((vDepthA < 0) != (vDepthB < 0) && vDepthA != vDepthB) {
      final vShare = vDepthA / (vDepthA - vDepthB);
      rBand.add(PlanPoint(vA.x + (vB.x - vA.x) * vShare, vA.y + (vB.y - vA.y) * vShare));
    }
  }

  return rBand;
}

double _polygonArea(List<PlanPoint> pPoints) {
  var vTwice = 0.0;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    vTwice += vA.x * vB.y - vB.x * vA.y;
  }

  return vTwice.abs() / 2;
}

/// Surface au sol sous la pente, en mm².
double slopedFloorMm2(Room pRoom) {
  final vSlope = activeSlope(pRoom);
  if (vSlope == null || pRoom.walls.length < 3) {
    return 0;
  }
  final rArea = _polygonArea(_band(pRoom, vSlope, vSlope.runMm.toDouble()));

  return rArea;
}

/// Surface du plafond : partie plate plus le pan incliné, plus grand que son ombre au sol.
double ceilingAreaMm2(Room pRoom) {
  final vFloor = outlineAreaMm2(pRoom);
  final vSlope = activeSlope(pRoom);
  if (vSlope == null) {
    return vFloor;
  }
  final vSloped = slopedFloorMm2(pRoom);
  final vRise = (pRoom.ceilingHeightMm - vSlope.lowMm).toDouble();
  final vStretch = math.sqrt(1 + math.pow(vRise / vSlope.runMm, 2));
  final rArea = vFloor - vSloped + vSloped * vStretch;

  return rArea;
}

/// Surface au sol où l'on tient debout (au moins 1,80 m sous plafond), utile pour un meuble ou
/// une mezzanine : la partie en pente plus basse que [pHeightMm] est retirée.
double standingFloorMm2(Room pRoom, {int pHeightMm = 1800}) {
  final vSlope = activeSlope(pRoom);
  final vFloor = outlineAreaMm2(pRoom);
  if (vSlope == null || pHeightMm <= vSlope.lowMm) {
    return vFloor;
  }
  final vShare = math.min((pHeightMm - vSlope.lowMm) / (pRoom.ceilingHeightMm - vSlope.lowMm), 1.0);
  final rArea = vFloor - _polygonArea(_band(pRoom, vSlope, vSlope.runMm * vShare));

  return rArea;
}

/// Contour de la partie en pente, vue de dessus ; vide sans plafond rampant.
List<PlanPoint> slopedOutline(Room pRoom) {
  final vSlope = activeSlope(pRoom);
  if (vSlope == null || pRoom.walls.length < 3) {
    return const [];
  }

  return _band(pRoom, vSlope, vSlope.runMm.toDouble());
}
