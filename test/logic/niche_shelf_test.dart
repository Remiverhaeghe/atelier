import 'package:atelier/logic/niche_shelf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('niche : tablettes avec du jeu, trois tasseaux chacune', () {
    final vPlan = planNiche(800, 300, 4);

    expect(vPlan.shelfLengthMm, 796);
    expect(vPlan.backCleatMm, 800);
    expect(vPlan.sideCleatMm, 280);
    expect(vPlan.cleats, 12);
    expect(vPlan.screws, 44);
  });

  test('sous un rampant à 45° : la tablette du haut recule', () {
    final vPlan = planUnderSlope(800, 45, 400, 4);

    expect(vPlan.sideBackMm, 800);
    expect(vPlan.sideFrontMm, 1200);
    expect(
      [for (final vShelf in vPlan.shelves) (vShelf.heightMm, vShelf.depthMm)],
      [(0, 400), (367, 400), (733, 400), (1100, 100)],
    );
  });

  test('rampant plus couché : la tablette du haut perd plus de profondeur', () {
    final vPlan = planUnderSlope(1000, 30, 500, 3);

    expect(vPlan.sideFrontMm, 1289);
    expect(vPlan.shelves.last, (heightMm: 1189, depthMm: 173));
  });

  test('saisies vides : rien de négatif', () {
    expect(planNiche(0, 0, 0).screws, 0);
    expect(planUnderSlope(800, 45, 400, 0).shelves.single.heightMm, 0);
  });
}
