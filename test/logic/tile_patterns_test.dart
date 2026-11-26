import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/tile_patterns.dart';
import 'package:atelier/logic/tiling.dart';
import 'package:flutter_test/flutter_test.dart';

const _gauge = (lengthMm: 600, widthMm: 300, jointMm: 3, sheetMm: 300);

double _coverage(List<TileShape> pShapes, double pLength, double pWidth) {
  // Part du rectangle couverte, échantillonnée sur une grille de points.
  var vHit = 0, vTotal = 0;
  for (var vX = 10.0; vX < pLength; vX += 37) {
    for (var vY = 10.0; vY < pWidth; vY += 37) {
      vTotal++;
      if (pShapes.any((pShape) => _contains(pShape, PlanPoint(vX, vY)))) {
        vHit++;
      }
    }
  }

  return vHit / vTotal;
}

bool _contains(TileShape pShape, PlanPoint pPoint) {
  var vInside = false;
  for (var vA = 0, vB = pShape.length - 1; vA < pShape.length; vB = vA++) {
    final vP = pShape[vA], vQ = pShape[vB];
    if ((vP.y > pPoint.y) != (vQ.y > pPoint.y) &&
        pPoint.x < (vQ.x - vP.x) * (pPoint.y - vP.y) / (vQ.y - vP.y) + vP.x) {
      vInside = !vInside;
    }
  }

  return vInside;
}

void main() {
  test('chaque pose recouvre presque toute la surface, joints exceptés', () {
    for (final vPattern in TilePattern.values) {
      final vShapes = tileShapes(vPattern, 3000, 2000, _gauge);

      expect(vShapes, isNotEmpty, reason: '$vPattern');
      expect(_coverage(vShapes, 3000, 2000), greaterThan(0.93), reason: '$vPattern');
    }
  });

  test('les chevrons ne se chevauchent pas : l\'aire cumulée ne dépasse pas la surface', () {
    final vShapes = tileShapes(TilePattern.herringbone, 3000, 2000, _gauge);
    var vInside = 0.0;
    for (final vShape in vShapes) {
      expect(polygonAreaM2(vShape), closeTo(0.6 * 0.3 * 0.99, 0.03));
      vInside += 1;
    }

    expect(vInside, greaterThan(30));
  });

  test('la diagonale tourne les carreaux de 45 degrés', () {
    final vShape = tileShapes(TilePattern.diagonal, 3000, 2000, _gauge).first;

    expect((vShape[1].x - vShape[0].x).abs(), closeTo((vShape[1].y - vShape[0].y).abs(), 0.001));
  });

  test('un hexagone a six côtés et ses côtés sont égaux', () {
    final vHexagon = tileShapes(TilePattern.hexagon, 2000, 2000, _gauge).first;

    expect(vHexagon, hasLength(6));
    final vSides = [
      for (var vIndex = 0; vIndex < 6; vIndex++) vHexagon[vIndex].distanceTo(vHexagon[(vIndex + 1) % 6]),
    ];
    for (final vSide in vSides) {
      expect(vSide, closeTo(vSides.first, 0.001));
    }
  });

  test('dimensions fausses ou trop de carreaux : rien n\'est dessiné', () {
    expect(tileShapes(TilePattern.straight, 0, 2000, _gauge), isEmpty);
    expect(
      tileShapes(TilePattern.mosaic, 3000, 2000, (lengthMm: 600, widthMm: 0, jointMm: 3, sheetMm: 300)),
      isEmpty,
    );
    expect(
      tileShapes(TilePattern.straight, 100000, 100000, (
        lengthMm: 20,
        widthMm: 20,
        jointMm: 2,
        sheetMm: 300,
      )),
      isEmpty,
    );
  });

  test('la perte de coupe recommandée est plus forte en diagonale qu\'en pose droite', () {
    expect(recommendedWastePercent(TilePattern.diagonal), greaterThan(recommendedWastePercent(TilePattern.straight)));
    expect(recommendedWastePercent(TilePattern.mosaic), lessThan(recommendedWastePercent(TilePattern.hexagon)));
  });

  test('plaques de mosaïque : le nombre se déduit de la surface avec la perte', () {
    final vNeeds = tilingNeeds(
      const TilingDesign(
        lengthMm: 3000,
        widthMm: 2000,
        pattern: TilePattern.mosaic,
        marginPercent: 8,
      ),
    );

    expect(vNeeds.sheets, 72);
    expect(tilingNeeds(const TilingDesign()).sheets, 0);
  });

  test('une pièce en L : la surface vient du contour, pas du rectangle englobant', () {
    const vL = [
      PlanPoint(0, 0),
      PlanPoint(4000, 0),
      PlanPoint(4000, 2000),
      PlanPoint(2000, 2000),
      PlanPoint(2000, 4000),
      PlanPoint(0, 4000),
    ];
    final vNeeds = tilingNeeds(
      const TilingDesign(lengthMm: 4000, widthMm: 4000, marginPercent: 0, outline: vL),
    );

    expect(polygonAreaM2(vL), closeTo(12, 0.0001));
    expect(vNeeds.areaM2, closeTo(12, 0.0001));
  });
}
