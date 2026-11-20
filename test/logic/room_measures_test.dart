import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_measures.dart';
import 'package:atelier/logic/units.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('cotes d\'une pièce de 4 × 3 m sous 2,50 m', () {
    final vMeasures = {
      for (final vMeasure in roomMeasures(rectangleRoom())) vMeasure.key: vMeasure.value,
    };
    expect(vMeasures[RoomMeasureKey.length], 4000);
    expect(vMeasures[RoomMeasureKey.width], 3000);
    expect(vMeasures[RoomMeasureKey.height], 2500);
    expect(vMeasures[RoomMeasureKey.perimeter], 14000);
    expect(vMeasures[RoomMeasureKey.floor], closeTo(12, 1e-9));
    expect(vMeasures[RoomMeasureKey.walls], closeTo(35, 1e-9));
    expect(vMeasures[RoomMeasureKey.volume], closeTo(30, 1e-9));
  });

  test('la surface des murs perd celle des ouvertures', () {
    final vRoom = rectangleRoom();
    final vWithDoor = vRoom.copyWith(
      walls: [
        vRoom.walls.first.copyWith(
          openings: const [Opening(kind: OpeningKind.door, offsetMm: 500, widthMm: 830)],
        ),
        ...vRoom.walls.skip(1),
      ],
    );
    final vWalls = roomMeasures(
      vWithDoor,
    ).firstWhere((pMeasure) => pMeasure.key == RoomMeasureKey.walls).value;
    expect(vWalls, closeTo(35 - 0.83 * 2.04, 1e-9));
  });

  test('pas de cote sans au moins trois murs', () {
    expect(roomMeasures(const Room(id: 'r', name: 'Vide')), isEmpty);
  });

  test('une cote ne va que dans un champ de la même nature, écrite dans son unité', () {
    expect(fitsField(RoomMeasureKey.length, FieldUnit.mm), isTrue);
    expect(fitsField(RoomMeasureKey.length, FieldUnit.m2), isFalse);
    expect(fitsField(RoomMeasureKey.floor, FieldUnit.m2), isTrue);
    expect(fitsField(RoomMeasureKey.volume, FieldUnit.m2), isFalse);
    const RoomMeasure vLength = (key: RoomMeasureKey.length, value: 4000);
    expect(measureInUnit(vLength, FieldUnit.cm), '400');
    expect(measureInUnit(vLength, FieldUnit.m), '4');
    expect(measureInUnit((key: RoomMeasureKey.floor, value: 12.5), FieldUnit.m2), '12,5');
  });
}
