import 'package:atelier/logic/garden.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pelouse semée : 35 g/m², boîtes de 1 kg', () {
    final vNeeds = gardenNeeds(const GardenDesign(lawnM2: 60));

    expect(vNeeds.seedBoxes, 3);
    expect(vNeeds.turfRolls, 0);
  });

  test('pelouse en rouleaux d\'1 m², 5 % de marge', () {
    final vNeeds = gardenNeeds(const GardenDesign(lawnM2: 60, turf: true));

    expect(vNeeds.turfRolls, 63);
    expect(vNeeds.seedBoxes, 0);
  });

  test('massif de 10 m² : terre sur 20 cm, paillage sur 7 cm, 5 plants au m²', () {
    final vNeeds = gardenNeeds(const GardenDesign(bedsM2: 10));

    // 2000 L de terre en sacs de 40 L, 700 L de paillage en sacs de 50 L
    expect(vNeeds.soilBags, 50);
    expect(vNeeds.mulchBags, 14);
    expect(vNeeds.plants, 50);
  });

  test('rien à acheter sans surface, même saisie négative', () {
    final vNeeds = gardenNeeds(const GardenDesign(lawnM2: -5, bedsM2: -2));

    expect(vNeeds, (seedBoxes: 0, turfRolls: 0, soilBags: 0, mulchBags: 0, plants: 0));
    expect(const GardenDesign().copyWith(turf: true).turf, isTrue);
  });
}
