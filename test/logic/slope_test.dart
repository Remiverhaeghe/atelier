import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/house_export.dart';
import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/slope.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Pièce de 4 × 3 m, 2,50 m sous plafond, pente de 2 m depuis le mur 1 qui ne fait que 1 m.
Room atticRoom() =>
    rectangleRoom().copyWith(slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 2000));

void main() {
  test('la hauteur monte du côté bas jusqu\'au plafond, puis reste plate', () {
    final vRoom = atticRoom();

    expect(ceilingHeightAt(vRoom, const PlanPoint(2000, 0)), 1000);
    expect(ceilingHeightAt(vRoom, const PlanPoint(2000, 1000)), 1750);
    expect(ceilingHeightAt(vRoom, const PlanPoint(2000, 2800)), 2500);
  });

  test('surface des murs : bas, haut et pignon en trapèze', () {
    final vRoom = atticRoom();

    expect(wallAreaMm2(vRoom, 0), closeTo(4e6, 1));
    expect(wallAreaMm2(vRoom, 2), closeTo(10e6, 1));
    // 2 m en pente de 1 m à 2,50 m, puis 1 m à 2,50 m
    expect(wallAreaMm2(vRoom, 1), closeTo(6e6, 1e3));
  });

  test('plafond : partie plate plus le pan incliné', () {
    final vRoom = atticRoom();

    expect(slopedFloorMm2(vRoom), closeTo(8e6, 1));
    // 4 m² plats + 8 m² au sol × 1,25 (pente de 1,50 m sur 2 m)
    expect(ceilingAreaMm2(vRoom), closeTo(14e6, 1));
    expect(paintAreas(vRoom).ceilingM2, closeTo(14, 1e-6));
    expect(slopedOutlines(vRoom).single, hasLength(4));
  });

  test('surface où l\'on tient debout : la bande trop basse est retirée', () {
    expect(standingFloorMm2(atticRoom()), closeTo(12e6 - 4000 * 2000 * 800 / 1500, 1));
    expect(standingFloorMm2(atticRoom(), pHeightMm: 900), closeTo(12e6, 1));
    expect(standingFloorMm2(rectangleRoom()), closeTo(12e6, 1));
  });

  test('pente inutilisable : plafond plat', () {
    for (final vSlope in const [
      Slope(wallIndex: 9, lowMm: 1000, runMm: 2000),
      Slope(wallIndex: 0, lowMm: 2500, runMm: 2000),
      Slope(wallIndex: 0, lowMm: 1000, runMm: 0),
    ]) {
      final vRoom = rectangleRoom().copyWith(slope: vSlope);
      expect(activeSlope(vRoom), isNull);
      expect(wallAreaMm2(vRoom, 1), 3000 * 2500);
      expect(ceilingAreaMm2(vRoom), closeTo(12e6, 1));
      expect(slopedFloorMm2(vRoom), 0);
      expect(slopedOutlines(vRoom), isEmpty);
      expect(ceilingHeightAt(vRoom, const PlanPoint(0, 0)), 2500);
    }
  });

  test('aller-retour JSON, suppression de la pente et export', () {
    final vBack = Room.fromJson(atticRoom().toJson());
    expect(vBack.slope!.lowMm, 1000);
    expect(vBack.slope!.runMm, 2000);
    expect(vBack.copyWith(clearSlope: true).slope, isNull);
    expect(rectangleRoom().toJson().containsKey('slope'), isFalse);

    final vPlan = exportPlan(Worksite(id: 'w', name: 'Maison démo', rooms: [atticRoom()]));
    final vRoom = (vPlan['rooms']! as List).single as Map<String, Object?>;
    expect(vRoom['slope'], {'wall': 0, 'low': 1000, 'run': 2000});
  });

  test('deux pans : hauteur, sol sous pente et recouvrement compté une fois', () {
    final vRoom = rectangleRoom().copyWith(
      slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 1500),
      slope2: const Slope(wallIndex: 2, lowMm: 1000, runMm: 1500),
    );

    expect(activeSlopes(vRoom), hasLength(2));
    expect(slopedFloorMm2(vRoom), closeTo(12e6, 1));
    expect(ceilingAreaMm2(vRoom), closeTo(12e6 * 1.41421356, 1e3));
    // 1,80 m atteint à 80 cm de chaque mur bas
    expect(standingFloorMm2(vRoom), closeTo(12e6 - 2 * 4000 * 800, 1));
    expect(slopedOutlines(vRoom), hasLength(2));
    expect(lowHeadroomLines(vRoom), hasLength(2));

    final vNarrow = rectangleRoom().copyWith(
      slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 2000),
      slope2: const Slope(wallIndex: 2, lowMm: 1000, runMm: 2000),
    );
    expect(slopedFloorMm2(vNarrow), closeTo(12e6, 1));
    expect(ceilingHeightAt(vNarrow, const PlanPoint(2000, 1500)), closeTo(2125, 1e-6));
    final vBack = Room.fromJson(vNarrow.toJson());
    expect(vBack.slope2!.runMm, 2000);
    expect(vBack.copyWith(clearSlope2: true).slope2, isNull);
  });

  test('largeur au sol tirée du rampant', () {
    expect(runFromRafter(pRafterMm: 2500, pLowMm: 1000, pHighMm: 2500), 2000);
    expect(runFromRafter(pRafterMm: 1400, pLowMm: 1000, pHighMm: 2500), isNull);
    expect(runFromRafter(pRafterMm: 2000, pLowMm: 2500, pHighMm: 2500), isNull);
  });

  test('ligne des 1,80 m sur le plan', () {
    final vLine = lowHeadroomLines(atticRoom()).single;

    expect(vLine.$1.y, closeTo(1066.67, 0.1));
    expect(vLine.$2.y, closeTo(1066.67, 0.1));
    expect((vLine.$1.x - vLine.$2.x).abs(), closeTo(4000, 0.1));
    // Jambette déjà à 1,80 m : pas de ligne
    final vHigh = rectangleRoom().copyWith(
      slope: const Slope(wallIndex: 0, lowMm: 2000, runMm: 1000),
    );
    expect(lowHeadroomLines(vHigh), isEmpty);
    expect(lowHeadroomLines(const Room(id: 'v', name: 'Vide')), isEmpty);
  });
}
