import 'package:atelier/logic/plumbing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('diamètres et eau chaude selon l\'appareil', () {
    expect(drainDiameterMm(Fixture.washbasin), 32);
    expect(drainDiameterMm(Fixture.shower), 40);
    expect(drainDiameterMm(Fixture.toilet), 100);
    expect(needsHotWater(Fixture.sink), isTrue);
    expect(needsHotWater(Fixture.washingMachine), isFalse);
  });

  test('salle de bain : tuyaux par diamètre, alimentation, coudes et raccords', () {
    final vNeeds = plumbingNeeds(const [
      (fixture: Fixture.washbasin, runMetres: 2),
      (fixture: Fixture.shower, runMetres: 3),
      (fixture: Fixture.toilet, runMetres: 1.5),
      (fixture: Fixture.washingMachine, runMetres: -1),
    ]);

    expect(vNeeds.drainMetresByDiameter, {32: 3, 40: 4, 100: 2});
    // (2 + 3) × 2 + 1,5 = 11,5 m, plus 10 %
    expect(vNeeds.supplyMetres, 13);
    expect(vNeeds.elbows, 8);
    expect(vNeeds.fittings, 6);
  });

  test('pente : de 1 à 3 cm par mètre', () {
    expect(drainDrop(3), (minMm: 30, maxMm: 90));
  });
}
