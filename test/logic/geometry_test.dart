import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('le contour d\'une pièce rectangulaire revient au point de départ', () {
    final vPoints = outline(rectangleRoom());

    expect(vPoints, hasLength(5));
    expect(vPoints[1].x, closeTo(4000, 0.001));
    expect(vPoints[2].y, closeTo(3000, 0.001));
    expect(closureGapMm(rectangleRoom()), closeTo(0, 0.001));
    expect(closesProperly(rectangleRoom()), isTrue);
  });

  test('surface d\'une pièce rectangulaire et d\'une pièce en L avec coin sortant', () {
    expect(floorAreaM2(rectangleRoom()), closeTo(12, 0.0001));
    expect(floorAreaM2(lShapedRoom()), closeTo(16, 0.0001));
    expect(closesProperly(lShapedRoom()), isTrue);
  });

  test('un mur mal mesuré empêche le contour de se refermer', () {
    final vRoom = rectangleRoom();
    final vWrong = vRoom.copyWith(walls: [...vRoom.walls]..[2] = const Wall(lengthMm: 3950));

    expect(closureGapMm(vWrong), closeTo(50, 0.001));
    expect(closesProperly(vWrong), isFalse);
  });

  test('1 cm d\'écart est toléré, pas davantage', () {
    final vRoom = rectangleRoom();
    final vAlmost = vRoom.copyWith(walls: [...vRoom.walls]..[2] = const Wall(lengthMm: 3991));
    final vTooFar = vRoom.copyWith(walls: [...vRoom.walls]..[2] = const Wall(lengthMm: 3988));

    expect(closesProperly(vAlmost), isTrue);
    expect(closesProperly(vTooFar), isFalse);
  });

  test('un coin pas d\'équerre décale le contour', () {
    final vRoom = rectangleRoom();
    final vSkewed = vRoom.copyWith(walls: [...vRoom.walls]..[0] = const Wall(lengthMm: 4000, angleToNextDeg: 88));

    expect(closesProperly(vSkewed), isFalse);
  });

  test('une pièce ouverte ne se contrôle pas', () {
    final vOpen = rectangleRoom().copyWith(closed: false);

    expect(closureGapMm(vOpen), 0);
    expect(closureGapMm(const Room(id: 'vide', name: 'Vide')), 0);
  });

  test('les zones sans parquet sont retirées de la surface', () {
    final vRoom = rectangleRoom(
      pObstacles: const [
        Obstacle(kind: ObstacleKind.cupboard, wallIndex: 1, offsetMm: 0, widthMm: 1000, depthMm: 600),
        Obstacle(kind: ObstacleKind.radiator, wallIndex: 0, offsetMm: 500, widthMm: 800),
      ],
    );

    expect(floorAreaM2(vRoom), closeTo(11.4, 0.0001));
  });

  test('moins de trois murs ne font pas de surface', () {
    const vRoom = Room(id: 'r', name: 'R', walls: [Wall(lengthMm: 1000), Wall(lengthMm: 1000)]);

    expect(outlineAreaMm2(vRoom), 0);
    expect(floorAreaM2(vRoom), 0);
  });

  test('une surface ne devient jamais négative', () {
    final vRoom = rectangleRoom(
      pObstacles: const [
        Obstacle(kind: ObstacleKind.fireplace, wallIndex: 0, offsetMm: 0, widthMm: 5000, depthMm: 5000),
      ],
    );

    expect(floorAreaM2(vRoom), 0);
  });

  test('périmètre et coin sortant', () {
    expect(perimeterMm(rectangleRoom()), 14000);
    expect(lShapedRoom().walls[2].isOutsideCornerAfter, isTrue);
    expect(lShapedRoom().walls[1].isOutsideCornerAfter, isFalse);
  });
}
