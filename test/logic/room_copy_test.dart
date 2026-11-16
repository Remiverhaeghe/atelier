import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_copy.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('copie : même plan, avancement remis à zéro', () {
    final vRoom = rectangleRoom().copyWith(
      laidRows: const [1, 2],
      cutPieces: const [0],
      touchUps: const [TouchUp(id: 't', label: 'Joint')],
    );
    final vCopy = duplicateRoom(vRoom, pId: 'chambre2', pName: 'Chambre 2');
    expect((vCopy.id, vCopy.name), ('chambre2', 'Chambre 2'));
    expect(vCopy.walls.map((pWall) => pWall.lengthMm), vRoom.walls.map((pWall) => pWall.lengthMm));
    expect(vCopy.laidRows, isEmpty);
    expect(vCopy.cutPieces, isEmpty);
    expect(vCopy.touchUps, isEmpty);
  });

  test('miroir d\'une pièce en L : même surface, fermée, coin rentrant gardé', () {
    final vRoom = lShapedRoom();
    final vMirror = mirrorRoom(vRoom, pId: 'm', pName: 'Miroir');
    expect(floorAreaM2(vMirror), closeTo(floorAreaM2(vRoom), 1e-6));
    expect(closesProperly(vMirror), isTrue);
    expect(
      vMirror.walls.map((pWall) => pWall.angleToNextDeg).toList()..sort(),
      vRoom.walls.map((pWall) => pWall.angleToNextDeg).toList()..sort(),
    );
    final vTwice = mirrorRoom(vMirror, pId: 'r', pName: 'Retour');
    expect(
      vTwice.walls.map((pWall) => (pWall.lengthMm, pWall.angleToNextDeg)),
      vRoom.walls.map((pWall) => (pWall.lengthMm, pWall.angleToNextDeg)),
    );
  });

  test('une ouverture se compte depuis l\'autre bout du mur', () {
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          angleToNextDeg: 90,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 500, widthMm: 900)],
        ),
        ...rectangleRoom().walls.skip(1),
      ],
    );
    final vMirror = mirrorRoom(vRoom, pId: 'm', pName: 'Miroir');
    final vDoorWall = vMirror.walls.firstWhere((pWall) => pWall.openings.isNotEmpty);
    expect(vDoorWall.openings.single.offsetMm, 4000 - 500 - 900);
    expect(vMirror.fixtures, isEmpty);
  });
}
