import 'package:atelier/logic/gutters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pan de 10 m sur 5 m en plan : une descente de 80', () {
    final vPlan = planGutter(10000, 5000);
    expect(vPlan.roofM2, 50);
    expect(vPlan.descents, 1);
    // 50 cm² : la descente de 80 mm offre 50,3 cm²
    expect(vPlan.diameterMm, 80);
    expect(vPlan.dropMm, 50);
    expect(vPlan.hooks, 21);
  });

  test('grande longueur : deux descentes, pente de chaque côté', () {
    final vPlan = planGutter(16000, 6000);
    expect(vPlan.descents, 2);
    expect(vPlan.diameterMm, 80);
    expect(vPlan.dropMm, 20);
    // 200 m² : la plus grosse descente ne suffit pas seule, il en faut deux
    final vBig = planGutter(10000, 20000);
    expect((vBig.descents, vBig.diameterMm), (2, 120));
    expect(planGutter(0, 5000).descents, 0);
  });
}
