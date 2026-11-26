/// Poses de carrelage et de mosaïque : formes des carreaux sur une surface, perte de coupe.
library;

import 'dart:math' as math;

import 'geometry.dart';

/// Manière de poser : le dessin décide de la perte de coupe et du nombre de coupes.
enum TilePattern { straight, brick, third, diagonal, herringbone, hexagon, mosaic }

/// Perte de coupe habituelle de chaque pose, en pourcentage de la surface.
int recommendedWastePercent(TilePattern pPattern) => switch (pPattern) {
  TilePattern.straight || TilePattern.brick => 10,
  TilePattern.third => 12,
  TilePattern.diagonal || TilePattern.herringbone || TilePattern.hexagon => 15,
  TilePattern.mosaic => 8,
};

/// Au-delà, on ne dessine plus les carreaux un à un : un plan illisible et lent.
const maxDrawnTiles = 6000;

/// Dimensions utilisées pour dessiner : carreau, joint et plaque de mosaïque, en millimètres.
typedef TileGauge = ({int lengthMm, int widthMm, int jointMm, int sheetMm});

typedef TileShape = List<PlanPoint>;

List<PlanPoint> _rect(double pX, double pY, double pWidth, double pHeight) => [
  PlanPoint(pX, pY),
  PlanPoint(pX + pWidth, pY),
  PlanPoint(pX + pWidth, pY + pHeight),
  PlanPoint(pX, pY + pHeight),
];

PlanPoint _rotate(PlanPoint pPoint, PlanPoint pCenter, double pCos, double pSin) {
  final vX = pPoint.x - pCenter.x;
  final vY = pPoint.y - pCenter.y;

  return PlanPoint(pCenter.x + vX * pCos - vY * pSin, pCenter.y + vX * pSin + vY * pCos);
}

bool _touches(TileShape pShape, double pLength, double pWidth) {
  var vMinX = double.infinity, vMaxX = -double.infinity;
  var vMinY = double.infinity, vMaxY = -double.infinity;
  for (final vPoint in pShape) {
    vMinX = math.min(vMinX, vPoint.x);
    vMaxX = math.max(vMaxX, vPoint.x);
    vMinY = math.min(vMinY, vPoint.y);
    vMaxY = math.max(vMaxY, vPoint.y);
  }

  return vMaxX > 0 && vMinX < pLength && vMaxY > 0 && vMinY < pWidth;
}

/// Carreaux (polygones, en mm) qui recouvrent un rectangle de [pLengthMm] sur [pWidthMm]
/// à partir du coin (0, 0). Ils débordent du rectangle : le dessin les découpe au contour.
/// Liste vide si les dimensions sont fausses ou si les carreaux seraient trop nombreux.
List<TileShape> tileShapes(TilePattern pPattern, int pLengthMm, int pWidthMm, TileGauge pGauge) {
  if (pLengthMm <= 0 || pWidthMm <= 0 || pGauge.lengthMm <= 0 || pGauge.widthMm <= 0) {
    return const [];
  }
  final vLength = pLengthMm.toDouble();
  final vWidth = pWidthMm.toDouble();
  final vJoint = pGauge.jointMm.toDouble();
  final vShapes = switch (pPattern) {
    TilePattern.straight => _grid(vLength, vWidth, pGauge, 0),
    TilePattern.brick => _grid(vLength, vWidth, pGauge, 2),
    TilePattern.third => _grid(vLength, vWidth, pGauge, 3),
    TilePattern.diagonal => _diagonal(vLength, vWidth, pGauge),
    TilePattern.herringbone => _herringbone(vLength, vWidth, pGauge),
    TilePattern.hexagon => _hexagons(vLength, vWidth, pGauge.widthMm.toDouble(), vJoint),
    TilePattern.mosaic => _sheets(vLength, vWidth, pGauge),
  };

  return vShapes.length > maxDrawnTiles ? const [] : vShapes;
}

/// Rangées de carreaux, décalées d'un [pDivisions]-ième de carreau d'une rangée à la suivante.
List<TileShape> _grid(double pLength, double pWidth, TileGauge pGauge, int pDivisions) {
  final vStepX = (pGauge.lengthMm + pGauge.jointMm).toDouble();
  final vStepY = (pGauge.widthMm + pGauge.jointMm).toDouble();
  final vShapes = <TileShape>[];
  final vRows = (pWidth / vStepY).ceil();
  if (vRows * (pLength / vStepX + 2) > maxDrawnTiles * 2) {
    return List.filled(maxDrawnTiles + 1, const <PlanPoint>[]);
  }
  for (var vRow = 0; vRow < vRows; vRow++) {
    final vShift = pDivisions == 0 ? 0.0 : (vRow % pDivisions) * vStepX / pDivisions;
    for (var vX = -vShift; vX < pLength; vX += vStepX) {
      vShapes.add(_rect(vX, vRow * vStepY, pGauge.lengthMm.toDouble(), pGauge.widthMm.toDouble()));
    }
  }

  return vShapes;
}

List<TileShape> _diagonal(double pLength, double pWidth, TileGauge pGauge) {
  final vCenter = PlanPoint(pLength / 2, pWidth / 2);
  final vRadius = math.sqrt(pLength * pLength + pWidth * pWidth) / 2;
  final vStepX = (pGauge.lengthMm + pGauge.jointMm).toDouble();
  final vStepY = (pGauge.widthMm + pGauge.jointMm).toDouble();
  final vCos = math.cos(math.pi / 4);
  final vSin = math.sin(math.pi / 4);
  final vShapes = <TileShape>[];
  for (var vY = -vRadius; vY < vRadius; vY += vStepY) {
    for (var vX = -vRadius; vX < vRadius; vX += vStepX) {
      final vShape = [
        for (final vPoint in _rect(
          vCenter.x + vX,
          vCenter.y + vY,
          pGauge.lengthMm.toDouble(),
          pGauge.widthMm.toDouble(),
        ))
          _rotate(vPoint, vCenter, vCos, vSin),
      ];
      if (_touches(vShape, pLength, pWidth)) {
        vShapes.add(vShape);
      }
      if (vShapes.length > maxDrawnTiles) {
        return vShapes;
      }
    }
  }

  return vShapes;
}

/// Point de Hongrie à 90° (chevrons droits) : bandes en escalier, une longueur de carreau
/// valant [n] largeurs, l'escalier se répète tous les 2n carreaux de large.
List<TileShape> _herringbone(double pLength, double pWidth, TileGauge pGauge) {
  final vCell = (pGauge.widthMm + pGauge.jointMm).toDouble();
  final vN = math.max(2, ((pGauge.lengthMm + pGauge.jointMm) / vCell).round());
  final vLong = vN * vCell - pGauge.jointMm;
  final vShort = pGauge.widthMm.toDouble();
  final vCellsX = (pLength / vCell).ceil() + 2 * vN;
  final vCellsY = (pWidth / vCell).ceil() + 2 * vN;
  final vShapes = <TileShape>[];
  for (var vBand = -vCellsY ~/ (2 * vN) - 1; vBand * 2 * vN <= vCellsX + vN; vBand++) {
    for (var vT = -vCellsY - vN; vT <= vCellsX + vN; vT++) {
      final vX = (vT + vBand * 2 * vN) * vCell;
      final vY = vT * vCell;
      final vHorizontal = _rect(vX, vY, vLong, vShort);
      final vVertical = _rect(vX + vN * vCell, vY + vCell - vN * vCell, vShort, vLong);
      for (final vShape in [vHorizontal, vVertical]) {
        if (_touches(vShape, pLength, pWidth)) {
          vShapes.add(vShape);
        }
      }
      if (vShapes.length > maxDrawnTiles) {
        return vShapes;
      }
    }
  }

  return vShapes;
}

/// Hexagones à pointe en haut ; [pFlatMm] est la largeur entre deux côtés plats.
List<TileShape> _hexagons(double pLength, double pWidth, double pFlatMm, double pJoint) {
  final vStepX = pFlatMm + pJoint;
  final vRowStep = vStepX / math.sqrt(3) * 1.5;
  final vRadius = pFlatMm / math.sqrt(3);
  final vShapes = <TileShape>[];
  for (var vRow = -1; vRow * vRowStep < pWidth + vRowStep; vRow++) {
    final vShift = vRow.isOdd ? vStepX / 2 : 0.0;
    for (var vX = -vStepX + vShift; vX < pLength + vStepX; vX += vStepX) {
      final vCy = vRow * vRowStep;
      vShapes.add([
        for (var vCorner = 0; vCorner < 6; vCorner++)
          PlanPoint(
            vX + vRadius * math.cos(math.pi / 6 + vCorner * math.pi / 3),
            vCy + vRadius * math.sin(math.pi / 6 + vCorner * math.pi / 3),
          ),
      ]);
    }
    if (vShapes.length > maxDrawnTiles) {
      return vShapes;
    }
  }

  return vShapes;
}

/// Plaques de mosaïque carrées, jointes entre elles comme des carreaux.
List<TileShape> _sheets(double pLength, double pWidth, TileGauge pGauge) {
  final vSheet = math.max(pGauge.sheetMm, 50).toDouble();
  final vStep = vSheet + pGauge.jointMm;
  final vShapes = <TileShape>[];
  for (var vY = 0.0; vY < pWidth; vY += vStep) {
    for (var vX = 0.0; vX < pLength; vX += vStep) {
      vShapes.add(_rect(vX, vY, vSheet, vSheet));
    }
    if (vShapes.length > maxDrawnTiles) {
      return vShapes;
    }
  }

  return vShapes;
}

/// Surface d'un polygone en mètres carrés (formule du lacet).
double polygonAreaM2(List<PlanPoint> pPoints) {
  var vTwiceArea = 0.0;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vNext = pPoints[(vIndex + 1) % pPoints.length];
    vTwiceArea += pPoints[vIndex].x * vNext.y - vNext.x * pPoints[vIndex].y;
  }

  return vTwiceArea.abs() / 2 / 1e6;
}
