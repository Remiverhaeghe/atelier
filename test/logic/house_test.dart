import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/house.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('quarts de tour puis décalage', () {
    const vPoint = PlanPoint(1000, 200);
    PlanPoint vAt(int pTurns) =>
        toHouse(rectangleRoom().copyWith(houseQuarterTurns: pTurns, houseXMm: 5000, houseYMm: 100), vPoint);

    expect([vAt(0).x, vAt(0).y], [6000, 300]);
    expect([vAt(1).x, vAt(1).y], [4800, 1100]);
    expect([vAt(2).x, vAt(2).y], [4000, -100]);
    expect([vAt(3).x, vAt(3).y], [5200, -900]);
    expect(rectangleRoom().copyWith(houseQuarterTurns: 5).houseQuarterTurns, 1);
  });

  test('les pièces pas encore placées se rangent côte à côte', () {
    final vRooms = arrangeUnplaced([
      rectangleRoom(),
      lShapedRoom(),
      const Room(id: 'z', name: 'Toit'),
      rectangleRoom().copyWith(houseYMm: 9000),
    ]);

    expect(vRooms[0].houseXMm, 0);
    expect(vRooms[1].houseXMm, 4500);
    expect(vRooms[2].houseXMm, 0);
    expect(vRooms[3].houseYMm, 9000);
    expect(snap(1234), 1250);
    expect(houseRooms(Worksite(id: 'w', name: 'M', rooms: vRooms)), hasLength(3));
    expect(houseOutline(vRooms[1]).first.x, 4500);
  });

  test('la place dans la maison se relit depuis le JSON', () {
    final vRoom = rectangleRoom().copyWith(houseXMm: 1200, houseYMm: -300, houseQuarterTurns: 3);
    final vBack = Room.fromJson(vRoom.toJson());

    expect([vBack.houseXMm, vBack.houseYMm, vBack.houseQuarterTurns], [1200, -300, 3]);
  });
}
