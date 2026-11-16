import 'package:atelier/logic/screed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ragréage de 12 m² à 5 mm de moyenne', () {
    final vPlan = planCoating(
      pCoating: Coating.selfLeveling,
      pAreaM2: 12,
      pThicknessMm: averageThickness(2, 8),
    );

    expect(vPlan.kg, closeTo(100.8, 1e-9));
    expect(vPlan.bags, 5);
    expect(vPlan.primerCans, 1);
    expect(vPlan.passes, 1);
    expect(vPlan.dryingHours, 48);
  });

  test('attente selon ce qui est posé dessus', () {
    expect(screedDryingHours(5, Covering.tiles), 24);
    expect(screedDryingHours(5, Covering.vinyl), 48);
    expect(screedDryingHours(5, Covering.gluedParquet), 96);
    expect(screedDryingHours(0, Covering.floating), 24);
  });

  test('enduit de lissage : couches de 2 mm, pas de primaire', () {
    final vPlan = planCoating(pCoating: Coating.skimCoat, pAreaM2: 10, pThicknessMm: 3);

    expect(vPlan.kg, closeTo(34.65, 1e-9));
    expect(vPlan.bags, 3);
    expect(vPlan.passes, 2);
    expect(vPlan.primerCans, 0);
    expect(vPlan.dryingHours, 48);
    expect(planCoating(pCoating: Coating.filler, pAreaM2: 1, pThicknessMm: 0.5).passes, 1);
  });
}
