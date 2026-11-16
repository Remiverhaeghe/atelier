import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Pièce de 400 × 300 cm, 2,50 m sous plafond, une porte de 83 cm et une fenêtre de 120 cm.
Room paintedRoom(PaintSettings pSettings) => rectangleRoom().copyWith(
  paint: pSettings,
  walls: const [
    Wall(
      lengthMm: 4000,
      openings: [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 830)],
    ),
    Wall(
      lengthMm: 3000,
      openings: [Opening(kind: OpeningKind.window, offsetMm: 900, widthMm: 1200)],
    ),
    Wall(lengthMm: 4000),
    Wall(lengthMm: 3000),
  ],
);

void main() {
  test('murs moins la porte et la fenêtre, plafond, porte et chambranle', () {
    final vAreas = paintAreas(paintedRoom(const PaintSettings(walls: true)));

    // 14 m × 2,5 m − 0,83 × 2,04 − 1,2 × 1,25
    expect(vAreas.wallsM2, closeTo(31.8068, 1e-6));
    expect(vAreas.ceilingM2, closeTo(12, 1e-6));
    // Chambranle de 7 cm sur deux montants et le haut, plus la face du vantail
    expect(vAreas.woodworkM2, closeTo(2.0369, 1e-6));
  });

  test('litres : couches, rendement et marge, seulement les produits choisis', () {
    final vOnlyWalls = paintLitres(paintedRoom(const PaintSettings(walls: true)), const PaintSettings(walls: true));
    expect(vOnlyWalls.keys, [PaintProduct.walls]);
    expect(vOnlyWalls[PaintProduct.walls], closeTo(6.9975, 1e-3));

    const vAll = PaintSettings(walls: true, ceiling: true, woodwork: true, primer: true);
    final vLitres = paintLitres(paintedRoom(vAll), vAll);
    expect(vLitres[PaintProduct.ceiling], closeTo(2.64, 1e-6));
    expect(vLitres[PaintProduct.woodwork], closeTo(0.3734, 1e-3));
    expect(vLitres[PaintProduct.primer], closeTo(4.8187, 1e-3));
  });

  test('rien à peindre sans murs ni choix, rendement nul ignoré', () {
    expect(paintLitres(const Room(id: 'r', name: 'R'), const PaintSettings(walls: true)), isEmpty);
    expect(paintLitres(paintedRoom(const PaintSettings()), const PaintSettings()), isEmpty);
    const vNothing = PaintSettings(walls: false);
    expect(paintLitres(paintedRoom(vNothing), vNothing), isEmpty);
    const vBroken = PaintSettings(walls: true, coverageM2PerL: 0);
    expect(paintLitres(paintedRoom(vBroken), vBroken), isEmpty);
  });

  test('pots : le grand pot revient moins cher au litre, sauf prix saisis', () {
    final vSizes = potSizes[PaintProduct.walls]!;

    expect(cheapestPots(7.7, vSizes, const {}), {10.0: 1});
    expect(cheapestPots(12, vSizes, const {}), {10.0: 1, 2.5: 1});
    expect(cheapestPots(7.7, vSizes, const {10.0: 80, 5.0: 30, 2.5: 18}), {5.0: 2});
    expect(cheapestPots(0.9, potSizes[PaintProduct.woodwork]!, const {}), {1.0: 1});
    expect(cheapestPots(0, vSizes, const {}), isEmpty);
  });

  test('fournitures : un rouleau par produit, bâche, ruban', () {
    const vSettings = PaintSettings(walls: true, ceiling: true);
    final vSupplies = paintSupplies(paintedRoom(vSettings), vSettings);

    expect(vSupplies.rollers, 2);
    expect(vSupplies.dropCloths, 1);
    expect(vSupplies.tapeRolls, 1);
    expect(paintSupplies(paintedRoom(const PaintSettings(walls: false)), const PaintSettings(walls: false)).rollers, 0);
  });

  test('réglages, hauteur et fenêtres se relisent depuis le JSON', () {
    const vSettings = PaintSettings(
      walls: true,
      ceiling: true,
      primer: true,
      coats: 3,
      extraPercent: 15,
    );
    final vRoom = paintedRoom(vSettings).copyWith(ceilingHeightMm: 2700);
    final vBack = Room.fromJson(vRoom.toJson());

    expect(vBack.ceilingHeightMm, 2700);
    expect(vBack.paint.toJson(), vSettings.toJson());
    expect(vBack.walls[1].openings.single.kind, OpeningKind.window);
    expect(vBack.walls[1].openings.single.sill, defaultSillMm);
    expect(PaintSettings.fromJson(const {}).toJson(), const PaintSettings().toJson());
  });

  test('une fenêtre ne coupe pas la plinthe', () {
    const vWindow = Opening(kind: OpeningKind.window, offsetMm: 0, widthMm: 1000);
    const vDoor = Opening(kind: OpeningKind.door, offsetMm: 0, widthMm: 800, heightMm: 2100);

    expect(vWindow.cutsBaseboard, isFalse);
    expect(vDoor.cutsBaseboard, isTrue);
    expect(vDoor.height, 2100);
    expect(vDoor.sill, 0);
  });
}
