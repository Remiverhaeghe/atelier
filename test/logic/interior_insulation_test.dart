import 'package:atelier/logic/insulation.dart';
import 'package:atelier/logic/interior_insulation.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('laine de verre sur fourrures : épaisseur, matériel et surface perdue', () {
    final vPlan = planLining(
      pRooms: [(room: rectangleRoom(), walls: {0, 1})],
      pInsulant: Insulant.glassWool,
      pSystem: LiningSystem.metalFrame,
    );
    expect(vPlan.layersMm, [140]);
    expect(vPlan.achievedR, closeTo(4, 1e-9));
    expect(vPlan.depthMm, 171);
    expect(vPlan.wallM2, closeTo(17.5, 1e-9));
    expect(vPlan.lostM2, closeTo(1.167759, 1e-9));
    expect(vPlan.insulantPacks, 4);
    expect(vPlan.vaporBarrierM2, closeTo(19.25, 1e-9));
    expect(vPlan.boards, 7);
    expect((vPlan.studs, vPlan.railsMetres, vPlan.brackets, vPlan.adhesiveBags), (14, 14, 28, 0));
    expect(vPlan.rooms.single.floorBeforeM2, 12);
  });

  test('doublage collé en polyuréthane : pas de pare-vapeur, de la colle', () {
    final vPlan = planLining(
      pRooms: [(room: rectangleRoom(), walls: {0, 1})],
      pInsulant: Insulant.polyurethane,
      pSystem: LiningSystem.gluedComplex,
    );
    expect(vPlan.layersMm, [100]);
    expect(vPlan.depthMm, 120);
    expect(vPlan.vaporBarrierM2, 0);
    expect(vPlan.adhesiveBags, 3);
    expect((vPlan.studs, vPlan.railsMetres, vPlan.brackets), (0, 0, 0));
    expect(needsVaporBarrier(Insulant.woodFibre), isTrue);
  });

  test('ossature bois : montants et rails, sans appuis', () {
    final vPlan = planLining(
      pRooms: [(room: rectangleRoom(), walls: {0})],
      pInsulant: Insulant.woodFibre,
      pSystem: LiningSystem.timberFrame,
      pTargetR: 3,
    );
    expect(vPlan.layersMm, [120]);
    expect(vPlan.depthMm, 133);
    expect((vPlan.studs, vPlan.railsMetres, vPlan.brackets), (8, 8, 0));
  });

  test('surface perdue : coins rentrants, coin sortant, pièce ouverte', () {
    final vRoom = rectangleRoom();
    expect(lostFloorM2(vRoom, {0, 1, 2, 3}, 171), closeTo(2.277036, 1e-9));
    expect(lostFloorM2(lShapedRoom(), {2, 3}, 171), closeTo(0.713241, 1e-9));
    final vOpen = vRoom.copyWith(closed: false);
    expect(lostFloorM2(vOpen, {3, 0}, 171), closeTo(1.197, 1e-9));
    // Mur inconnu ignoré
    expect(lostFloorM2(vRoom, {9}, 171), 0);
  });

  test('fenêtres déduites du mur, pièce sans mur choisi laissée de côté', () {
    final vRoom = rectangleRoom().copyWith(
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
    expect(liningWallM2(vRoom, 0), closeTo(8.5, 1e-9));
    final vPlan = planLining(
      pRooms: [
        (room: vRoom, walls: {0}),
        (room: rectangleRoom(), walls: {7}),
      ],
      pInsulant: Insulant.rockWool,
      pSystem: LiningSystem.metalFrame,
    );
    expect(vPlan.rooms.single.windows, 1);
    final vNone = planLining(
      pRooms: const [],
      pInsulant: Insulant.rockWool,
      pSystem: LiningSystem.metalFrame,
    );
    expect((vNone.boards, vNone.lostM2, vNone.railsMetres), (0, 0, 0));
    // Une ouverture plus grande que le mur ne donne pas de surface négative
    const vTiny = Room(
      id: 't',
      name: 'Tout vitré',
      ceilingHeightMm: 1000,
      walls: [
        Wall(
          lengthMm: 1000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 0, widthMm: 1000)],
        ),
      ],
    );
    expect(liningWallM2(vTiny, 0), 0);
  });
}
