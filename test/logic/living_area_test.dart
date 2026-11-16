import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/living_area.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/slope.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('pièce droite : tout le sol compte, gaine et escalier retirés', () {
    final vRoom = rectangleRoom(
      pObstacles: const [
        Obstacle(kind: ObstacleKind.pipe, wallIndex: 0, offsetMm: 0, widthMm: 200, depthMm: 500),
        Obstacle(kind: ObstacleKind.cupboard, wallIndex: 1, offsetMm: 0, widthMm: 600, depthMm: 600),
      ],
    ).copyWith(
      fixtures: const [
        Fixture(
          id: 'e',
          kind: FixtureKind.stairs,
          xMm: 3500,
          yMm: 1500,
          widthMm: 800,
          depthMm: 2500,
        ),
        Fixture(id: 'p', kind: FixtureKind.socket, xMm: 0, yMm: 0),
      ],
    );
    final vArea = roomLivingArea(vRoom);

    // 12 m² − 0,1 m² de gaine − 2 m² d'escalier ; le placard reste compté
    expect(vArea.habitable, closeTo(9.9, 1e-9));
    expect(vArea.carrez, closeTo(9.9, 1e-9));
    expect(lowFloorM2(vRoom), 0);
  });

  test('sous la pente, la partie à moins de 1,80 m ne compte pas', () {
    final vRoom = rectangleRoom().copyWith(
      slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 2000),
    );

    // 1,80 m atteint à 1,067 m du mur bas, sur 4 m de long
    expect(lowFloorM2(vRoom), closeTo(4.2667, 1e-3));
    expect(roomLivingArea(vRoom).habitable, closeTo(7.7333, 1e-3));
  });

  test('trémie retirée à l\'étage, pièce trop basse ou ouverte ignorée', () {
    final vUpstairs = rectangleRoom().copyWith(
      level: 1,
      fixtures: const [
        Fixture(id: 't', kind: FixtureKind.stairwell, xMm: 500, yMm: 1500, widthMm: 900, depthMm: 2000),
      ],
    );
    expect(roomLivingArea(vUpstairs).habitable, closeTo(10.2, 1e-9));

    final vLow = rectangleRoom().copyWith(ceilingHeightMm: 1700);
    expect(roomLivingArea(vLow).habitable, 0);
    expect(lowFloorM2(vLow), closeTo(12, 1e-9));

    final vOpen = rectangleRoom().copyWith(closed: false);
    expect(roomLivingArea(vOpen).carrez, 0);
    expect(lowFloorM2(vOpen), 0);
  });

  test('usage : combles et véranda en Loi Carrez seulement, garage nulle part', () {
    final vRooms = [
      rectangleRoom(),
      rectangleRoom().copyWith(usage: RoomUsage.attic),
      rectangleRoom().copyWith(usage: RoomUsage.veranda),
      rectangleRoom().copyWith(usage: RoomUsage.garage),
      rectangleRoom().copyWith(usage: RoomUsage.cellar),
      rectangleRoom().copyWith(usage: RoomUsage.outdoor),
    ];
    final vTotal = totalLivingArea(vRooms);

    expect(vTotal.habitable, closeTo(12, 1e-9));
    expect(vTotal.carrez, closeTo(36, 1e-9));
  });

  test('l\'usage s\'enregistre, habitable par défaut', () {
    final vGarage = rectangleRoom().copyWith(usage: RoomUsage.garage);

    expect(Room.fromJson(vGarage.toJson()).usage, RoomUsage.garage);
    expect(rectangleRoom().toJson().containsKey('usage'), isFalse);
    expect(Room.fromJson(rectangleRoom().toJson()).usage, RoomUsage.habitable);
  });
}
