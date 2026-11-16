import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/house.dart';
import 'package:atelier/logic/house_export.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/view3d.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Rez-de-chaussée de 2,50 m, étage de 2,40 m, sous-sol de 2,00 m.
List<Room> threeLevels() => [
  rectangleRoom(),
  Room(id: 'ch', name: 'Chambre', walls: rectangleRoom().walls, level: 1, ceilingHeightMm: 2400),
  Room(id: 'cave', name: 'Cave', walls: rectangleRoom().walls, level: -1, ceilingHeightMm: 2000),
];

void main() {
  test('niveaux présents, rez-de-chaussée compris', () {
    expect(houseLevels(threeLevels()), [-1, 0, 1]);
    expect(houseLevels(const []), [0]);
  });

  test('altitude des sols : étages empilés, plancher de 20 cm', () {
    final vRooms = threeLevels();

    expect(levelBaseMm(vRooms, 0), 0);
    expect(levelBaseMm(vRooms, 1), 2700);
    expect(levelBaseMm(vRooms, 2), 2700 + 2600);
    expect(levelBaseMm(vRooms, -1), -2200);
    // Niveau vide en dessous : 2,50 m par défaut
    expect(levelBaseMm(vRooms, -2), -2200 - 2700);
  });

  test('3D : chaque niveau posé sur le précédent, dessiné du bas vers le haut', () {
    final vFaces = houseFaces(threeLevels(), 0);
    final vFloors = vFaces.where((pFace) => pFace.kind == FaceKind.floor).toList();

    expect([for (final vFloor in vFloors) vFloor.corners.first.z], [-2200, 0, 2700]);
    expect(vFaces.first.corners.first.z, -2200);
    expect(vFaces.last.corners.map((pCorner) => pCorner.z).reduce((pA, pB) => pA > pB ? pA : pB), 2700 + 2400);
  });

  test('la trémie est retirée du sol de l\'étage', () {
    final vRoom = rectangleRoom().copyWith(
      fixtures: const [
        Fixture(id: 't', kind: FixtureKind.stairwell, xMm: 500, yMm: 1500, widthMm: 900, depthMm: 2800),
      ],
    );

    expect(floorAreaM2(vRoom), closeTo(12 - 2.52, 1e-9));
    expect(defaultFixtureSize(FixtureKind.stairwell), (widthMm: 900, depthMm: 2800));
  });

  test('niveau relu depuis le JSON et exporté avec l\'altitude du sol', () {
    final vRooms = threeLevels();
    expect(Room.fromJson(vRooms[1].toJson()).level, 1);
    expect(vRooms.first.toJson().containsKey('level'), isFalse);

    final vPlan = exportPlan(Worksite(id: 'w', name: 'Maison démo', rooms: vRooms));
    final vExported = [for (final vRoom in vPlan['rooms']! as List) vRoom as Map<String, Object?>];
    expect([for (final vRoom in vExported) vRoom['floorLevel']], [0, 2700, -2200]);
    expect(vExported[2]['level'], -1);
  });
}
