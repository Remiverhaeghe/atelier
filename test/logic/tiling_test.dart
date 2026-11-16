import 'package:atelier/logic/tiling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calepinage centré : coupes égales, jamais plus étroites qu\'un tiers de carreau', () {
    expect(layoutAxis(3000, 600, 3, pCentered: true), (fullTiles: 4, startCutMm: 292, endCutMm: 293));
    expect(layoutAxis(2000, 300, 3, pCentered: true), (fullTiles: 5, startCutMm: 241, endCutMm: 241));
    // 1220 mm : 2 carreaux laisseraient 7 mm de chaque côté, on en pose 1 et deux coupes de 30,7 cm
    expect(layoutAxis(1220, 600, 3, pCentered: true), (fullTiles: 1, startCutMm: 307, endCutMm: 307));
  });

  test('départ d\'un bord, longueur juste, rien à carreler', () {
    expect(layoutAxis(3000, 600, 3, pCentered: false), (fullTiles: 4, startCutMm: 0, endCutMm: 588));
    expect(layoutAxis(2400, 600, 0, pCentered: true), (fullTiles: 4, startCutMm: 0, endCutMm: 0));
    expect(layoutAxis(0, 600, 3, pCentered: true), (fullTiles: 0, startCutMm: 0, endCutMm: 0));
  });

  test('quantités de 3 × 2 m en 60 × 30 : carreaux, cartons, colle, joint, croisillons', () {
    final vNeeds = tilingNeeds(const TilingDesign());

    expect(vNeeds.areaM2, 6);
    expect(vNeeds.tiles, 37);
    expect(vNeeds.boxes, 5);
    expect(vNeeds.glueKg, 30);
    expect(vNeeds.jointKg, 1.3);
    expect(vNeeds.spacers, 37);
    expect(tilingNeeds(const TilingDesign(tileLengthMm: 0, boxM2: 0)).tiles, 0);
    expect(const TilingDesign().copyWith(centered: false).centered, isFalse);
  });
}
