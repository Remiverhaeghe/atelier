import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/window_frame.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

Fixture _roof(String pId, int pWidth, int pDepth, {bool pPlexi = true}) => Fixture(
  id: pId,
  kind: FixtureKind.roofWindow,
  xMm: 1000,
  yMm: 1000,
  widthMm: pWidth,
  depthMm: pDepth,
  plexi: pPlexi,
);

void main() {
  test('plexis regroupés par taille, surface totale', () {
    final vRooms = [
      rectangleRoom().copyWith(
        fixtures: [_roof('a', 780, 980), _roof('b', 780, 980), _roof('c', 550, 780, pPlexi: false)],
      ),
      const Room(
        id: 'ch',
        name: 'Chambre',
      ).copyWith(fixtures: [_roof('d', 780, 980), _roof('e', 450, 550)]),
    ];
    final vSizes = plexiSizes(vRooms);

    expect((vSizes.first.widthMm, vSizes.first.heightMm, vSizes.first.count), (780, 980, 3));
    expect(vSizes.first.rooms, ['Salon', 'Chambre']);
    expect(vSizes.last.count, 1);
    expect(plexiAreaM2(vRooms), closeTo(3 * 0.7644 + 0.2475, 1e-9));
    expect(plexiSizes([rectangleRoom()]), isEmpty);
  });

  test('cadre pour un Velux de 78 × 98 en double vitrage', () {
    final vPlan = planFrame(780, 980, Glazing.doubleGlazing)!;

    expect((vPlan.outerWidthMm, vPlan.outerHeightMm), (770, 970));
    expect((vPlan.stileMm, vPlan.railMm), (970, 770));
    expect(vPlan.rebateDepthMm, 42);
    expect(vPlan.depthMm, 60);
    expect((vPlan.glassWidthMm, vPlan.glassHeightMm), (710, 910));
    expect(vPlan.beadsMm, 3264);
    expect(vPlan.stockPieces, 2);
  });

  test('vitrage plus fin, ouverture trop petite', () {
    expect(planFrame(780, 980, Glazing.plexi)!.depthMm, 40);
    expect(planFrame(150, 150, Glazing.polycarbonate), isNull);
    expect(Glazing.laminatedGlass.thicknessMm, 9);
  });

  test('le plexi s\'enregistre avec la fenêtre de toit', () {
    final vBack = Fixture.fromJson(_roof('a', 780, 980).toJson());
    expect(vBack.plexi, isTrue);
    expect(_roof('b', 1, 1, pPlexi: false).toJson().containsKey('plexi'), isFalse);
    expect(vBack.copyWith(plexi: false).plexi, isFalse);
  });

  test('fenêtre de toit courante la plus proche et reprise du chevêtre', () {
    // Plexi de 78 × 98 : la taille courante du même nom, 2 cm de jeu au chevêtre
    expect(nearestRoofWindow(780, 980), (widthMm: 780, heightMm: 980, widenMm: 20, heightenMm: 20));
    // Ouverture de 80 × 120 : 78 × 118 tient sans couper de chevron
    final vMatch = nearestRoofWindow(800, 1200);
    expect((vMatch.widthMm, vMatch.heightMm), (780, 1180));
    expect((vMatch.widenMm, vMatch.heightenMm), (0, 0));
    // Ouverture étroite de 50 × 75 : la plus petite, chevêtre à agrandir
    expect(nearestRoofWindow(500, 750).widthMm, 550);
  });
}
