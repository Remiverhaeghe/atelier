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
bool _usable(Room pRoom, Slope? pSlope) =>
    pSlope != null &&
    pSlope.wallIndex < pRoom.walls.length &&
    pSlope.runMm > 0 &&
    pSlope.lowMm < pRoom.ceilingHeightMm;

/// Pans utilisables de la pièce : un ou deux (combles avec une pente de chaque côté).
List<Slope> activeSlopes(Room pRoom) => [
  for (final vSlope in [pRoom.slope, pRoom.slope2])
    if (_usable(pRoom, vSlope)) vSlope!,
];

/// Premier pan utilisable, ou null sans plafond rampant.
Slope? activeSlope(Room pRoom) => activeSlopes(pRoom).firstOrNull;

/// Largeur au sol d'une pente mesurée le long du rampant, de la jambette à la cassure du plafond.
int? runFromRafter({required int pRafterMm, required int pLowMm, required int pHighMm}) {
  final vRise = pHighMm - pLowMm;
  if (vRise <= 0 || pRafterMm <= vRise) {
    return null;
  }
  final rRun = math.sqrt(pRafterMm * pRafterMm - vRise * vRise).round();

  return rRun;
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

double _heightUnder(Room pRoom, Slope pSlope, PlanPoint pPoint) {
  final vShare = (_depthFromLowWall(pRoom, pSlope, pPoint) / pSlope.runMm).clamp(0.0, 1.0);

  return pSlope.lowMm + (pRoom.ceilingHeightMm - pSlope.lowMm) * vShare;
}

/// Hauteur sous plafond à un endroit de la pièce : le pan le plus bas l'emporte.
double ceilingHeightAt(Room pRoom, PlanPoint pPoint) {
  var rHeight = pRoom.ceilingHeightMm.toDouble();
  for (final vSlope in activeSlopes(pRoom)) {
    rHeight = math.min(rHeight, _heightUnder(pRoom, vSlope, pPoint));
  }

  return rHeight;
}

/// Surface d'un mur, du sol au plafond, pente comprise (portes et fenêtres non retirées).
double wallAreaMm2(Room pRoom, int pWallIndex) {
  final vLength = pRoom.walls[pWallIndex].lengthMm.toDouble();
  if (activeSlopes(pRoom).isEmpty) {
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

/// Polygone [pPolygon] coupé par le demi-plan des points à moins de [pDepthMm] du mur bas.
List<PlanPoint> _clip(Room pRoom, List<PlanPoint> pPolygon, Slope pSlope, double pDepthMm) {
  final rBand = <PlanPoint>[];
  for (var vIndex = 0; vIndex < pPolygon.length; vIndex++) {
    final vA = pPolygon[vIndex];
    final vB = pPolygon[(vIndex + 1) % pPolygon.length];
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

List<PlanPoint> _band(Room pRoom, Slope pSlope, double pDepthMm) =>
    _clip(pRoom, outline(pRoom).take(pRoom.walls.length).toList(), pSlope, pDepthMm);

double _polygonArea(List<PlanPoint> pPoints) {
  var vTwice = 0.0;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    vTwice += vA.x * vB.y - vB.x * vA.y;
  }

  return vTwice.abs() / 2;
}

/// Surface couverte par les bandes de chaque pan, sans compter deux fois leur recouvrement.
double _bandsArea(Room pRoom, List<(Slope, double)> pBands) {
  var rArea = 0.0;
  for (final (vSlope, vDepth) in pBands) {
    rArea += _polygonArea(_band(pRoom, vSlope, vDepth));
  }
  if (pBands.length == 2) {
    final (vFirst, vFirstDepth) = pBands.first;
    final (vSecond, vSecondDepth) = pBands.last;
    rArea -= _polygonArea(_clip(pRoom, _band(pRoom, vFirst, vFirstDepth), vSecond, vSecondDepth));
  }

  return rArea;
}

/// Surface au sol sous la pente, en mm².
double slopedFloorMm2(Room pRoom) {
  if (pRoom.walls.length < 3) {
    return 0;
  }
  final rArea = _bandsArea(pRoom, [
    for (final vSlope in activeSlopes(pRoom)) (vSlope, vSlope.runMm.toDouble()),
  ]);

  return rArea;
}

/// Surface du plafond : partie plate plus les pans inclinés, plus grands que leur ombre au sol.
double ceilingAreaMm2(Room pRoom) {
  final vSlopes = activeSlopes(pRoom);
  final vFloor = outlineAreaMm2(pRoom);
  if (vSlopes.isEmpty || pRoom.walls.length < 3) {
    return vFloor;
  }
  var rArea = vFloor - slopedFloorMm2(pRoom);
  for (final vSlope in vSlopes) {
    final vRise = (pRoom.ceilingHeightMm - vSlope.lowMm).toDouble();
    final vStretch = math.sqrt(1 + math.pow(vRise / vSlope.runMm, 2));
    rArea += _polygonArea(_band(pRoom, vSlope, vSlope.runMm.toDouble())) * vStretch;
  }

  return rArea;
}

/// Profondeur, depuis le mur bas, où le pan atteint [pHeightMm] ; null s'il n'y descend pas.
double? _depthAtHeight(Room pRoom, Slope pSlope, int pHeightMm) {
  if (pHeightMm <= pSlope.lowMm) {
    return null;
  }
  final vShare = math.min((pHeightMm - pSlope.lowMm) / (pRoom.ceilingHeightMm - pSlope.lowMm), 1.0);

  return pSlope.runMm * vShare;
}

/// Surface au sol où l'on tient debout (au moins 1,80 m sous plafond), utile pour un meuble ou
/// une mezzanine : la partie en pente plus basse que [pHeightMm] est retirée.
double standingFloorMm2(Room pRoom, {int pHeightMm = 1800}) {
  final vFloor = outlineAreaMm2(pRoom);
  if (pRoom.walls.length < 3) {
    return vFloor;
  }
  final vBands = [
    for (final vSlope in activeSlopes(pRoom))
      if (_depthAtHeight(pRoom, vSlope, pHeightMm) case final double vDepth) (vSlope, vDepth),
  ];
  final rArea = vFloor - _bandsArea(pRoom, vBands);

  return rArea;
}

/// Contours des parties en pente, vues de dessus ; vide sans plafond rampant.
List<List<PlanPoint>> slopedOutlines(Room pRoom) => [
  if (pRoom.walls.length >= 3)
    for (final vSlope in activeSlopes(pRoom)) _band(pRoom, vSlope, vSlope.runMm.toDouble()),
];

/// Lignes du plan où la hauteur sous plafond passe à 1,80 m, une par pan qui descend plus bas.
List<(PlanPoint, PlanPoint)> lowHeadroomLines(Room pRoom, {int pHeightMm = 1800}) {
  final rLines = <(PlanPoint, PlanPoint)>[];
  if (pRoom.walls.length < 3) {
    return rLines;
  }
  for (final vSlope in activeSlopes(pRoom)) {
    final vDepth = _depthAtHeight(pRoom, vSlope, pHeightMm);
    if (vDepth == null || vDepth >= vSlope.runMm) {
      continue;
    }
    // Points du bord de la bande qui sont sur la ligne elle-même
    final vOnLine = [
      for (final vPoint in _band(pRoom, vSlope, vDepth))
        if ((_depthFromLowWall(pRoom, vSlope, vPoint) - vDepth).abs() < 1) vPoint,
    ];
    if (vOnLine.length >= 2) {
      rLines.add((vOnLine.first, vOnLine.last));
    }
  }

  return rLines;
}
