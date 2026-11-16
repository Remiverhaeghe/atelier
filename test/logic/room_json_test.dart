import 'dart:convert';

import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('un chantier relu depuis le JSON est identique', () {
    final vRoom = rectangleRoom(
      pObstacles: const [
        Obstacle(kind: ObstacleKind.cupboard, wallIndex: 1, offsetMm: 100, widthMm: 900, depthMm: 600),
      ],
    ).copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          angleToNextDeg: 88.5,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 830)],
        ),
        const Wall(lengthMm: 3000, freeEndAfter: true),
      ],
      closed: false,
    );
    final vWorksite = Worksite(id: 'maison', name: 'Maison', rooms: [vRoom]);

    final vCopy = Worksite.fromJson(
      jsonDecode(jsonEncode(vWorksite.toJson())) as Map<String, Object?>,
    );

    expect(jsonEncode(vCopy.toJson()), jsonEncode(vWorksite.toJson()));
    expect(vCopy.rooms.single.walls.first.openings.single.widthMm, 830);
    expect(vCopy.rooms.single.walls.last.freeEndAfter, isTrue);
    expect(vCopy.rooms.single.closed, isFalse);
    expect(vCopy.rooms.single.obstacles.single.depthMm, 600);
  });

  test('les champs absents prennent leur valeur par défaut', () {
    final vRoom = Room.fromJson({
      'id': 'r',
      'name': 'Chambre',
      'walls': [
        {'lengthMm': 1200, 'angleToNextDeg': 90},
      ],
      'obstacles': [
        {'kind': 'pipe', 'wallIndex': 0, 'offsetMm': 10, 'widthMm': 30},
      ],
    });

    expect(vRoom.closed, isTrue);
    expect(vRoom.walls.single.openings, isEmpty);
    expect(vRoom.walls.single.freeEndAfter, isFalse);
    expect(vRoom.obstacles.single.depthMm, 0);
    expect(Worksite.fromJson({'id': 'w', 'name': 'W'}).rooms, isEmpty);
  });
}
