import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_shapes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pièce fermée faite des murs de la forme, pour vérifier qu'elle se referme.
Room closedRoom(ShapedRoom pShaped) =>
    Room(id: 'p', name: 'Pièce fictive', walls: shapeWalls(pShaped, const []));

void main() {
  test('rectangle sans mesure : la forme par défaut, qui se referme', () {
    final vShaped = shapeRoom(RoomShape.rectangle, const {});

    expect(vShaped.lengths, [4000, 3000, 4000, 3000]);
    expect(closesProperly(closedRoom(vShaped)), isTrue);
    expect(vShaped.needsDiagonal, isFalse);
  });

  test('rectangle : deux murs mesurés, les murs d\'en face en sont déduits', () {
    final vShaped = shapeRoom(RoomShape.rectangle, const {0: 4210, 1: 3180});

    expect(vShaped.lengths, [4210, 3180, 4210, 3180]);
    expect(vShaped.deduced, {2, 3});
    expect(closesProperly(closedRoom(vShaped)), isTrue);
  });

  test('rectangle aux murs d\'en face différents : la diagonale donne les angles', () {
    const vMeasured = {0: 4000, 1: 3000, 2: 4050, 3: 3000};
    final vWithout = shapeRoom(RoomShape.rectangle, vMeasured);
    expect(vWithout.needsDiagonal, isTrue);
    expect(vWithout.angles, everyElement(90.0));

    final vWith = shapeRoom(RoomShape.rectangle, vMeasured, pDiagonalMm: 5020);
    expect(vWith.needsDiagonal, isFalse);
    expect(vWith.angles.where((pAngle) => pAngle != 90), isNotEmpty);
    expect(vWith.angles.fold(0.0, (pSum, pAngle) => pSum + pAngle), closeTo(360, 1));
    // Diagonale impossible avec ces murs
    expect(shapeRoom(RoomShape.rectangle, vMeasured, pDiagonalMm: 9000).impossible, isTrue);
  });

  test('L : quatre murs mesurés, les deux autres déduits', () {
    final vShaped = shapeRoom(RoomShape.lShape, const {0: 6000, 1: 2000, 4: 3500, 5: 4200});

    expect(vShaped.lengths, [6000, 2000, 2500, 2200, 3500, 4200]);
    expect(vShaped.deduced, {2, 3});
    expect(closesProperly(closedRoom(vShaped)), isTrue);
  });

  test('L impossible : le retour est plus long que le mur d\'en face', () {
    expect(shapeRoom(RoomShape.lShape, const {0: 2000, 4: 3500}).impossible, isTrue);
  });

  test('T : la barre et le pied mesurés, le reste se cale par symétrie', () {
    final vShaped = shapeRoom(RoomShape.tShape, const {0: 1200, 4: 5000, 1: 2500, 3: 1800});

    // Les bouts de la barre et les côtés du pied se répondent ; le dessous se partage
    expect(vShaped.lengths, [1200, 2500, 1900, 1800, 5000, 1800, 1900, 2500]);
    expect(vShaped.deduced, {2, 5, 6, 7});
    expect(closesProperly(closedRoom(vShaped)), isTrue);
  });

  test('forme reconnue dans des murs déjà saisis, ouvertures gardées', () {
    final vWalls = shapeWalls(shapeRoom(RoomShape.lShape, const {}), const []);
    expect(shapeOf(vWalls), RoomShape.lShape);
    expect(shapeOf(const [Wall(lengthMm: 3000), Wall(lengthMm: 2000)]), isNull);

    const vDoor = Opening(kind: OpeningKind.door, offsetMm: 500, widthMm: 830);
    final vKept = shapeWalls(shapeRoom(RoomShape.rectangle, const {}), const [
      Wall(lengthMm: 1000, openings: [vDoor]),
    ]);
    expect(vKept.first.openings, [vDoor]);
    expect(vKept.first.lengthMm, 4000);
  });

  test('murs déduits gardés dans la pièce, effacés quand on retape la longueur', () {
    final vWalls = shapeWalls(shapeRoom(RoomShape.rectangle, const {0: 4200, 1: 3100}), const []);
    expect(vWalls.map((pWall) => pWall.deduced), [false, false, true, true]);
    final vRoom = Room(id: 'p', name: 'Pièce fictive', walls: vWalls);
    expect(wallsToMeasure(vRoom), [3, 4]);

    final vBack = Wall.fromJson(vWalls[2].toJson());
    expect(vBack.deduced, isTrue);
    expect(vWalls[0].toJson().containsKey('deduced'), isFalse);
    expect(vWalls[2].copyWith(lengthMm: 4210).deduced, isFalse);
    expect(vWalls[2].copyWith(angleToNextDeg: 91).deduced, isTrue);
  });

  test('plan papier tracé : rectangle redressé, mur le plus long de chaque sens déduit', () {
    final vWalls = shapeFromTrace(const [
      Wall(lengthMm: 4010, angleToNextDeg: 88),
      Wall(lengthMm: 2995, angleToNextDeg: 92),
      Wall(lengthMm: 3990, angleToNextDeg: 89),
      Wall(lengthMm: 3005, angleToNextDeg: 91),
    ])!;

    expect(vWalls.map((pWall) => pWall.angleToNextDeg), everyElement(90));
    expect(vWalls.map((pWall) => pWall.lengthMm), [3990, 2995, 3990, 2995]);
    expect(vWalls.map((pWall) => pWall.deduced), [true, false, false, true]);
    expect(shapeOf(vWalls), RoomShape.rectangle);
  });

  test('plan papier tracé en L, commencé à un autre coin : le tour est repris', () {
    final vWalls = shapeFromTrace(const [
      Wall(lengthMm: 1990, angleToNextDeg: 273),
      Wall(lengthMm: 2010, angleToNextDeg: 89),
      Wall(lengthMm: 3000, angleToNextDeg: 91),
      Wall(lengthMm: 4005, angleToNextDeg: 90),
      Wall(lengthMm: 4995, angleToNextDeg: 87),
      Wall(lengthMm: 2000, angleToNextDeg: 92),
    ])!;

    expect(shapeOf(vWalls), RoomShape.lShape);
    expect(vWalls.map((pWall) => pWall.lengthMm), [4990, 2000, 1990, 2010, 3000, 4010]);
    expect(vWalls.map((pWall) => pWall.deduced), [true, false, false, false, false, true]);
    expect(closesProperly(Room(id: 'p', name: 'Pièce fictive', walls: vWalls)), isTrue);
  });

  test('plan papier sans angle droit ou de forme inconnue : rien de proposé', () {
    expect(
      shapeFromTrace(const [
        Wall(lengthMm: 3000, angleToNextDeg: 60),
        Wall(lengthMm: 3000, angleToNextDeg: 60),
        Wall(lengthMm: 3000, angleToNextDeg: 60),
      ]),
      isNull,
    );
    expect(
      shapeFromTrace([for (var vIndex = 0; vIndex < 5; vIndex++) const Wall(lengthMm: 2000)]),
      isNull,
    );
  });
}
