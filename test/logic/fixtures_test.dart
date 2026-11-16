import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/house_export.dart';
import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

const _socketBlock = Fixture(id: 'p', kind: FixtureKind.socket, xMm: 100, yMm: 0, count: 2);
const _switch = Fixture(id: 'i', kind: FixtureKind.lightSwitch, xMm: 900, yMm: 0);
const _velux = Fixture(
  id: 'v',
  kind: FixtureKind.roofWindow,
  xMm: 2000,
  yMm: 1500,
  widthMm: 780,
  depthMm: 980,
);
const _mezzanine = Fixture(
  id: 'm',
  kind: FixtureKind.mezzanine,
  xMm: 1500,
  yMm: 1000,
  widthMm: 3000,
  depthMm: 2000,
);
const _stairs = Fixture(
  id: 'e',
  kind: FixtureKind.stairs,
  xMm: 3500,
  yMm: 1500,
  widthMm: 800,
  depthMm: 3000,
  riseMm: 2800,
);

void main() {
  test('les coins sont nommés A, B, C… puis A2 au-delà de Z', () {
    expect(cornerName(0), 'A');
    expect(cornerName(25), 'Z');
    expect(cornerName(26), 'A2');
    expect(wallCorners(1), (from: 'B', to: 'C'));
    expect(wallCorners(3, pClosesRoom: true), (from: 'D', to: 'A'));
  });

  test('prises et interrupteurs comptés, blocs compris', () {
    const vFixtures = [_socketBlock, _switch, _velux];

    expect(fixtureCount(vFixtures, FixtureKind.socket), 2);
    expect(fixtureCount(vFixtures, FixtureKind.lightSwitch), 1);
    expect(_switch.areaM2, 0);
  });

  test('surfaces : fenêtre de toit et mezzanine', () {
    const vFixtures = [_velux, _mezzanine, _socketBlock];

    expect(roofWindowsM2(vFixtures), closeTo(0.7644, 1e-9));
    expect(mezzaninesM2(vFixtures), closeTo(6, 1e-9));
  });

  test('la fenêtre de toit est retirée du plafond à peindre', () {
    final vRoom = rectangleRoom().copyWith(fixtures: const [_velux]);

    expect(paintAreas(vRoom).ceilingM2, closeTo(12 - 0.7644, 1e-6));
  });

  test("escalier par la loi de Blondel : 2,80 m en 16 marches de 17,5 cm", () {
    final vPlan = stairPlan(2800);

    expect(vPlan.risers, 16);
    expect(vPlan.riserMm, 175);
    expect(vPlan.goingMm, 280);
    expect(vPlan.runMm, 15 * 280);
    expect(stairPlan(50).risers, 1);
  });

  test('tailles proposées selon l\'élément', () {
    expect(defaultFixtureSize(FixtureKind.roofWindow), (widthMm: 780, depthMm: 980));
    expect(defaultFixtureSize(FixtureKind.stairs).depthMm, 3000);
    expect(defaultFixtureSize(FixtureKind.mezzanine).widthMm, 3000);
    expect(defaultFixtureSize(FixtureKind.socket), (widthMm: 0, depthMm: 0));
  });

  test('aller-retour JSON de la pièce avec ses éléments', () {
    final vRoom = rectangleRoom().copyWith(fixtures: const [_socketBlock, _stairs]);
    final vBack = Room.fromJson(vRoom.toJson());

    expect(vBack.fixtures, hasLength(2));
    expect(vBack.fixtures.first.count, 2);
    expect(vBack.fixtures.first.toJson().containsKey('widthMm'), isFalse);
    expect(vBack.fixtures.last.riseMm, 2800);
    expect(vBack.fixtures.last.depthMm, 3000);
    expect(rectangleRoom().toJson().containsKey('fixtures'), isFalse);
    expect(Room.fromJson(rectangleRoom().toJson()).fixtures, isEmpty);
  });

  test('copie modifiée et export des éléments pour la domotique', () {
    final vMoved = _stairs.copyWith(xMm: 10, yMm: 20, widthMm: 900, depthMm: 2800, count: 1);
    expect((vMoved.xMm, vMoved.yMm, vMoved.widthMm, vMoved.riseMm), (10, 20, 900, 2800));

    final vPlan = exportPlan(
      Worksite(
        id: 'w',
        name: 'Maison démo',
        rooms: [
          rectangleRoom().copyWith(fixtures: const [_socketBlock, _velux]),
        ],
      ),
    );
    final vRoom = (vPlan['rooms']! as List).single as Map<String, Object?>;
    final vFixtures = vRoom['fixtures']! as List;

    expect(vFixtures.first, {'kind': 'socket', 'x': 100, 'y': 0, 'count': 2});
    expect(vFixtures.last, {
      'kind': 'roofWindow',
      'x': 2000,
      'y': 1500,
      'width': 780,
      'depth': 980,
    });
  });
}
