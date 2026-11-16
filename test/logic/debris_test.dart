import 'package:atelier/logic/debris.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('volume en place, foisonné et poids', () {
    const vTiles = (kind: DebrisKind.rubble, areaM2: 10.0, thicknessMm: 60);
    expect(inPlaceM3(vTiles), closeTo(0.6, 1e-9));
    expect(bulkM3(vTiles), closeTo(0.9, 1e-9));
    expect(debrisKg(vTiles), closeTo(1200, 1e-9));
  });

  test('big bags et voyages comptés benne par benne, le poids limite les gravats', () {
    final vPlan = debrisPlan(const [
      (kind: DebrisKind.rubble, areaM2: 10, thicknessMm: 60),
      (kind: DebrisKind.rubble, areaM2: 5, thicknessMm: 20),
      (kind: DebrisKind.plaster, areaM2: 20, thicknessMm: 13),
      (kind: DebrisKind.insulation, areaM2: 0, thicknessMm: 100),
    ]);

    // Gravats : 0,7 m³ en place, 1,05 m³ en vrac, 1 400 kg
    expect([for (final vBin in vPlan.bins) vBin.kind], [DebrisKind.rubble, DebrisKind.plaster]);
    expect(vPlan.bins.first.kg, closeTo(1400, 1e-9));
    expect(vPlan.kg, closeTo(1400 + 234, 1e-9));
    // 2 big bags de gravats (poids et volume), 1 de plâtre
    expect(vPlan.bigBags, 3);
    // 3 voyages de gravats pour le poids, 1 de plâtre
    expect(vPlan.trips, 4);
    expect(vPlan.bulkM3, closeTo(1.05 + 0.26 * 1.4, 1e-9));
  });

  test('rien à évacuer', () {
    final vPlan = debrisPlan(const []);
    expect(vPlan.bins, isEmpty);
    expect((vPlan.bigBags, vPlan.trips, vPlan.kg), (0, 0, 0.0));
  });
}
