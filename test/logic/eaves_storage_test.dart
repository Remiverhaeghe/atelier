import 'package:atelier/logic/eaves_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genou de 60 cm, rampant à 45°, façade à 1,20 m sur 2,40 m', () {
    final vPlan = planEavesStorage(
      pKneeWallMm: 600,
      pSlopeDeg: 45,
      pLengthMm: 2400,
      pFrontMm: 1200,
    )!;
    expect(vPlan.depthMm, 600);
    expect(vPlan.modules, 4);
    expect(vPlan.moduleMm, 600);
    expect(vPlan.sides, 5);
    expect(vPlan.doorHeightMm, 1100);
    expect(vPlan.hingesPerDoor, 3);
    expect(vPlan.binWidthMm, 560);
    expect(vPlan.binDepthMm, 550);
    expect(vPlan.binHeightMm, 400);
    expect(vPlan.shelf, (heightMm: 450, depthMm: 600));
    // 8,22 m² de panneaux, 15 % de chutes : deux panneaux
    expect(vPlan.panels, 2);
    expect(vPlan.litres, 1296);
  });

  test('rampant à 30° : le placard est plus profond pour la même façade', () {
    final vPlan = planEavesStorage(
      pKneeWallMm: 400,
      pSlopeDeg: 30,
      pLengthMm: 1000,
      pFrontMm: 900,
    )!;
    expect(vPlan.depthMm, 866);
    expect(vPlan.modules, 2);
    expect(vPlan.moduleMm, 500);
    expect(vPlan.hingesPerDoor, 2);
    expect(vPlan.binHeightMm, 350);
  });

  test('façade basse : pas de place pour une tablette au-dessus des bacs', () {
    final vPlan = planEavesStorage(pKneeWallMm: 500, pSlopeDeg: 45, pLengthMm: 600, pFrontMm: 700)!;
    expect(vPlan.shelf, isNull);
  });

  test('façade pas plus haute que le genou, ou toit à plat : pas de placard', () {
    expect(
      planEavesStorage(pKneeWallMm: 800, pSlopeDeg: 45, pLengthMm: 2000, pFrontMm: 800),
      isNull,
    );
    expect(
      planEavesStorage(pKneeWallMm: 600, pSlopeDeg: 0, pLengthMm: 2000, pFrontMm: 1000),
      isNull,
    );
  });

  test('charnières selon la hauteur de porte', () {
    expect(eavesHinges(900), 2);
    expect(eavesHinges(1600), 3);
    expect(eavesHinges(1800), 4);
  });
}
