import 'package:atelier/logic/blown_insulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('60 m² de combles en laine de verre pour R = 7', () {
    final vPlan = planBlown(60, BlownMaterial.glassWool);
    expect((vPlan.settledMm, vPlan.blownMm, vPlan.bags, vPlan.rulers), (315, 331, 15, 6));
  });

  test('ouate de cellulose : plus de tassement, donc plus d\'épaisseur à souffler', () {
    final vPlan = planBlown(60, BlownMaterial.cellulose);
    expect((vPlan.settledMm, vPlan.blownMm, vPlan.bags), (280, 336, 52));
    expect(planBlown(60, BlownMaterial.rockWool, pTargetR: 8).settledMm, 352);
    expect(planBlown(0, BlownMaterial.glassWool).bags, 0);
  });
}
