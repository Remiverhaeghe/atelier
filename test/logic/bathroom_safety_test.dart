import 'package:atelier/logic/bathroom.dart';
import 'package:atelier/logic/bathroom_safety.dart';
import 'package:atelier/logic/kitchen_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

const Shower _aShower = (
  widthMm: 1200,
  depthMm: 900,
  drain: DrainKind.centre,
  siphonMm: 80,
  pipeMm: 2500,
  walls: 3,
);

void main() {
  test('volumes de sécurité autour de la douche', () {
    expect(zonePlan(_aShower), (
      zone1WidthMm: 1200,
      zone1DepthMm: 900,
      zone2WidthMm: 1200,
      zone2DepthMm: 1500,
    ));
    final vCorner = (
      widthMm: 900,
      depthMm: 900,
      drain: DrainKind.centre,
      siphonMm: 80,
      pipeMm: 2500,
      walls: 2,
    );
    expect(zonePlan(vCorner).zone2WidthMm, 1500);
    final vOneWall = (
      widthMm: 900,
      depthMm: 900,
      drain: DrainKind.centre,
      siphonMm: 80,
      pipeMm: 2500,
      walls: 1,
    );
    expect(zonePlan(vOneWall).zone2WidthMm, 2100);
    final vWalkIn = zonePlan(_aShower, pWalkIn: true);
    expect((vWalkIn.zone1WidthMm, vWalkIn.zone1DepthMm, vWalkIn.zone2WidthMm), (2400, 1200, 2400));

    expect(zoneAt(-10, 1000), BathZone.zone1);
    expect(zoneAt(0, 2400), BathZone.zone2);
    expect(zoneAt(500, 1000), BathZone.zone2);
    expect(zoneAt(700, 1000), BathZone.outside);
    expect(zoneAt(0, 3100), BathZone.outside);
    expect(zoneRule(BathZone.zone0).ip, 'IPX7');
    expect(zoneRule(BathZone.zone2).lights, isTrue);
    expect(zoneRule(BathZone.zone2).sockets, isFalse);
    expect(zoneRule(BathZone.outside).sockets, isTrue);
    expect(zoneRule(BathZone.zone1).switches, isFalse);
  });

  test('pente du receveur', () {
    expect(slopePercent(12, 600), 2);
    expect(slopePercent(5, 0), 0);
    expect(slopeVerdict(0.5), SlopeVerdict.tooFlat);
    expect(slopeVerdict(2), SlopeVerdict.good);
    expect(slopeVerdict(4), SlopeVerdict.tooSteep);
  });

  test('étanchéité liquide sous carrelage et ventilation', () {
    final vSeal = sealPlan(_aShower);
    // Sol 1,08 m², murs (1,2 + 2 × 0,9) × 2 m = 6 m²
    expect(vSeal.areaM2, closeTo(7.08, 1e-9));
    expect(vSeal.kg, closeTo(9.204, 1e-9));
    expect(vSeal.pots, 2);
    expect(vSeal.sleeves, 3);
    final vNone = sealPlan((
      widthMm: 0,
      depthMm: 0,
      drain: DrainKind.centre,
      siphonMm: 80,
      pipeMm: 0,
      walls: 0,
    ));
    expect(vNone.pots, 0);

    final vAir = bathAir(pMainRooms: 3, pVolumeM3: 15);
    expect((vAir.flowM3h, vAir.undercutMm), (30, 10));
    expect(vAir.changesPerHour, 2);
    expect(bathAir(pMainRooms: 1, pVolumeM3: 0).changesPerHour, 0);
  });

  test('cuisine : triangle, hotte et implantations', () {
    final vGood = checkTriangle(1500, 2000, 1800);
    expect(vGood.totalMm, 5300);
    expect(vGood.issues, isEmpty);
    expect(checkTriangle(800, 1500, 1500).issues, [
      TriangleIssue.sideTooShort,
      TriangleIssue.totalTooShort,
    ]);
    expect(checkTriangle(3000, 2700, 2700).issues, [
      TriangleIssue.sideTooLong,
      TriangleIssue.totalTooLong,
    ]);

    expect(hoodFor(30), (neededM3h: 300, hoodM3h: 300));
    expect(hoodFor(36), (neededM3h: 360, hoodM3h: 400));
    expect(hoodFor(120).hoodM3h, 900);
    expect(hoodFor(0).neededM3h, 0);

    expect(kitchenLayouts(1700, 3000), [KitchenLayout.linear]);
    expect(kitchenLayouts(3000, 2000), [KitchenLayout.linear, KitchenLayout.lShape]);
    expect(kitchenLayouts(2400, 3000), [
      KitchenLayout.linear,
      KitchenLayout.parallel,
      KitchenLayout.lShape,
      KitchenLayout.uShape,
    ]);
    expect(kitchenLayouts(4000, 4500), contains(KitchenLayout.island));
    expect(kitchenLayouts(1000, 1500), isEmpty);
    expect(roomBox(rectangleRoom()), (widthMm: 3000, lengthMm: 4000));
  });
}
