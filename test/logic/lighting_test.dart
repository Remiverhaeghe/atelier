import 'package:atelier/logic/lighting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('atelier de 8 × 6 m, lampes à 5 m : 16 lampes de 5000 lm en 4 × 4', () {
    final vPlan = planLighting(
      pLengthMm: 8000,
      pWidthMm: 6000,
      pHeightMm: 5000,
      pUse: LightUse.workshop,
      pLampLumens: 5000,
    );
    // 500 lx × 48 m² / (0,4 × 0,8)
    expect(vPlan.lumens, 75000);
    expect(vPlan.lamps, 16);
    expect((vPlan.columns, vPlan.rows), (4, 4));
    expect(vPlan.spacingMm, 2000);
    expect(vPlan.watts, 800);
  });

  test('séjour de 5 × 4 m sous 2,50 m : 6 lampes de 1500 lm', () {
    final vPlan = planLighting(
      pLengthMm: 5000,
      pWidthMm: 4000,
      pHeightMm: 2500,
      pUse: LightUse.living,
      pLampLumens: 1500,
    );
    expect(vPlan.lumens, 8334);
    expect(vPlan.lamps, 6);
    expect((vPlan.columns, vPlan.rows), (3, 2));
    expect(vPlan.watts, 90);
  });

  test('long couloir : on ajoute des lampes pour ne pas laisser de zone sombre', () {
    final vPlan = planLighting(
      pLengthMm: 20000,
      pWidthMm: 1000,
      pHeightMm: 2500,
      pUse: LightUse.corridor,
      pLampLumens: 5000,
    );
    expect(vPlan.columns, 6);
    expect(vPlan.rows, 1);
    expect(vPlan.spacingMm, lessThanOrEqualTo(3750));
  });

  test('le facteur d’utilisation baisse avec la hauteur', () {
    expect(utilisationFactor(2500), 0.6);
    expect(utilisationFactor(3500), 0.5);
    expect(utilisationFactor(6000), 0.4);
  });
}
