import 'package:atelier/logic/concrete.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dalle de 3 × 2 m sur 10 cm, marge comprise', () {
    expect(slabM3(3000, 2000, 100), closeTo(0.66, 1e-9));
    final vPlan = planConcrete(0.66);
    expect(vPlan.cementBags, 10);
    expect((vPlan.sandKg, vPlan.gravelKg, vPlan.waterLitres), (449, 776, 116));
    expect(vPlan.readyBags, 39);
    expect(vPlan.batches, 6);
    expect(vPlan.truck, isFalse);
  });

  test('plots de clôture et grande dalle en toupie', () {
    expect(footingsM3(13, 300, 500), closeTo(0.6435, 1e-9));
    expect(planConcrete(slabM3(6000, 4000, 120)).truck, isTrue);
    expect(planConcrete(0).cementBags, 0);
  });
}
