import 'package:atelier/logic/drywall.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('doublage de 4 m sur 2,50 m avec 10 cm de laine', () {
    final vNeeds = drywallNeeds(const DrywallDesign());

    expect(vNeeds.areaM2, 10);
    expect(vNeeds.plates, 4);
    expect(vNeeds.rails, 3);
    expect(vNeeds.studs, 8);
    expect(vNeeds.screws, 200);
    expect(vNeeds.tapeRolls, 1);
    expect(vNeeds.fillerBags, 1);
    expect(vNeeds.insulationRolls, 3);
    expect(vNeeds.resistance, closeTo(2.857, 1e-3));
  });

  test('une cloison double les plaques et les vis, pas l\'ossature', () {
    final vNeeds = drywallNeeds(const DrywallDesign(partition: true));

    expect(vNeeds.plates, 8);
    expect(vNeeds.screws, 400);
    expect(vNeeds.studs, 8);
  });

  test('au-dessus de 3 m, deux profilés par montant ; sans laine, ni rouleau ni R', () {
    final vNeeds = drywallNeeds(
      const DrywallDesign(heightMm: 3200, insulationMm: 0, studSpacingMm: 0),
    );

    expect(vNeeds.studs, 16);
    expect(vNeeds.insulationRolls, 0);
    expect(vNeeds.resistance, 0);
    expect(drywallNeeds(const DrywallDesign(lengthMm: 0, lambda: 0)).studs, 0);
    expect(const DrywallDesign().copyWith(partition: true).partition, isTrue);
  });
}
