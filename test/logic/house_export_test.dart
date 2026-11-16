import 'dart:convert';

import 'package:atelier/logic/house_export.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('plan exporté : format, version, contour, murs et ouvertures', () {
    final vRoom = rectangleRoom().copyWith(
      ceilingHeightMm: 2600,
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        Wall(lengthMm: 3000),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
    );
    final vPlan = exportPlan(
      Worksite(
        id: 'w',
        name: 'Maison',
        rooms: [
          vRoom,
          const Room(id: 'z', name: 'Toit'),
        ],
      ),
    );

    expect(vPlan['format'], 'atelier-plan');
    expect(vPlan['version'], 1);
    final vRooms = vPlan['rooms']! as List<Object?>;
    expect(vRooms, hasLength(1));
    final vExported = vRooms.single! as Map<String, Object?>;
    expect(vExported['ceilingHeight'], 2600);
    expect(vExported['floorArea'], 12000000);
    expect(vExported['outline'], [
      [0, 0],
      [4000, 0],
      [4000, 3000],
      [0, 3000],
    ]);
    final vWindow =
        ((vExported['walls']! as List<Object?>).first! as Map<String, Object?>)['openings']!
            as List<Object?>;
    expect(vWindow.single, {
      'kind': 'window',
      'offset': 1000,
      'width': 1200,
      'height': 1250,
      'sill': 900,
    });
    // Le plan passe tel quel en JSON
    expect(jsonDecode(jsonEncode(vPlan)), vPlan);
  });
}
