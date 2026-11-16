import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('chambre de 2,50 m : 3 lés par rouleau', () {
    final vPlan = planWallpaper(14000, 2500);
    expect(vPlan.stripMm, 2600);
    expect(vPlan.stripsPerRoll, 3);
    // 14 m / 53 cm = 26,4, donc 27 lés et un de plus
    expect(vPlan.strips, 28);
    expect(vPlan.rolls, 10);
    expect(vPlan.gluePacks, 2);
  });

  test('raccord du motif : lé arrondi au motif, moins de lés par rouleau', () {
    final vPlan = planWallpaper(14000, 2500, pRepeatMm: 640);
    expect(vPlan.stripMm, 3200);
    expect(vPlan.stripsPerRoll, 3);
    expect(planWallpaper(14000, 3300, pRepeatMm: 640).stripsPerRoll, 2);
  });

  test('plafond très haut : chaque lé prend un rouleau, au-delà de 10 m il en faut deux', () {
    expect(planWallpaper(2000, 5500).stripsPerRoll, 1);
    final vHigh = planWallpaper(2000, 10500);
    expect(vHigh.stripsPerRoll, 0);
    expect(vHigh.rolls, vHigh.strips * 2);
    expect(planWallpaper(0, 2500).rolls, 0);
  });

  test('murs de la pièce, ouvertures déduites', () {
    expect(wallpaperLengthMm(rectangleRoom()), 14000);
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 200, widthMm: 900)],
        ),
        ...rectangleRoom().walls.skip(1),
      ],
    );
    expect(wallpaperLengthMm(vRoom), 13100);
  });
}
