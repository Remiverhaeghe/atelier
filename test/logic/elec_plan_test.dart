import 'package:atelier/logic/elec_plan.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

Fixture _point(String pId, FixtureKind pKind, int pX, int pY, {int pCount = 1}) =>
    Fixture(id: pId, kind: pKind, xMm: pX, yMm: pY, count: pCount);

void main() {
  test('prises reliées de proche en proche, interrupteur à part', () {
    final vRoom = rectangleRoom().copyWith(
      fixtures: [
        _point('a', FixtureKind.socket, 0, 0, pCount: 2),
        _point('c', FixtureKind.socket, 3000, 4000),
        _point('b', FixtureKind.socket, 3000, 0),
        _point('i', FixtureKind.lightSwitch, 500, 0),
        const Fixture(
          id: 'v',
          kind: FixtureKind.roofWindow,
          xMm: 0,
          yMm: 0,
          widthMm: 780,
          depthMm: 980,
        ),
      ],
    );
    final vPlan = elecPlan([vRoom, rectangleRoom()]);

    expect((vPlan.sockets, vPlan.lights, vPlan.boxes), (4, 1, 5));
    expect((vPlan.socketCircuits, vPlan.lightCircuits), (1, 1));
    expect(vPlan.sheath20Mm, 3000 + 4000 + 3 * 1200);
    expect(vPlan.sheath16Mm, 1200);
    expect(vPlan.wire25Mm, 3 * 10600 + 4 * 300);
    expect(vPlan.wire15Mm, 3 * 1200 + 300);
  });

  test('sans point, rien ; au-delà de 12 prises, un second circuit', () {
    expect(elecPlan([rectangleRoom()]).socketCircuits, 0);
    final vMany = rectangleRoom().copyWith(
      fixtures: [
        for (var vIndex = 0; vIndex < 13; vIndex++)
          _point('$vIndex', FixtureKind.socket, vIndex * 100, 0),
      ],
    );
    expect(elecPlan([vMany]).socketCircuits, 2);
  });
}
