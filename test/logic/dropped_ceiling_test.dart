import 'package:atelier/logic/dropped_ceiling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pièce de 5 × 4 m à 3,50 m, abaissée à 2,50 m', () {
    final vPlan = planDroppedCeiling(
      pLengthMm: 5000,
      pWidthMm: 4000,
      pHeightMm: 3500,
      pWantedMm: 2500,
    );
    // 1000 mm moins la plaque et la fourrure
    expect(vPlan.plenumMm, 960);
    expect(vPlan.hanging, Hanging.rod);
    // 4 m tous les 60 cm : 6 fourrures pendues, les bords sur la cornière
    expect(vPlan.rows, 6);
    expect(vPlan.furringBars, 12);
    expect(vPlan.joints, 6);
    expect(vPlan.hangers, 30);
    expect(vPlan.rods, 30);
    expect(vPlan.angleBars, 6);
    expect(vPlan.boards, 8);
    expect(vPlan.screws, 300);
    expect(vPlan.savedVolumeM3, closeTo(20, 1e-9));
    expect(vPlan.tooLow, isFalse);
  });

  test('le sens de saisie ne change rien : les fourrures suivent la grande longueur', () {
    final vA = planDroppedCeiling(pLengthMm: 4000, pWidthMm: 5000, pHeightMm: 3500, pWantedMm: 2500);
    expect(vA.rows, 6);
    expect(vA.hangers, 30);
  });

  test('petit plénum : suspentes seules ; grand : ossature contreventée', () {
    final vSmall = planDroppedCeiling(
      pLengthMm: 3000,
      pWidthMm: 1000,
      pHeightMm: 2600,
      pWantedMm: 2500,
    );
    expect(vSmall.plenumMm, 60);
    expect(vSmall.hanging, Hanging.direct);
    expect(vSmall.rods, 0);
    expect(vSmall.rows, 1);
    expect(vSmall.hangers, 3);

    final vTall = planDroppedCeiling(
      pLengthMm: 3000,
      pWidthMm: 3000,
      pHeightMm: 4500,
      pWantedMm: 2500,
    );
    expect(vTall.hanging, Hanging.braced);
    // 1960 mm de plénum : deux tiges d'un mètre par suspente
    expect(vTall.rods, vTall.hangers * 2);
  });

  test('sous 2,20 m, le plafond est trop bas pour une pièce à vivre', () {
    final vPlan = planDroppedCeiling(
      pLengthMm: 3000,
      pWidthMm: 3000,
      pHeightMm: 2500,
      pWantedMm: 2100,
    );
    expect(vPlan.tooLow, isTrue);
  });

  test('plafond plus bas que voulu, ou pièce vide : rien à pendre', () {
    final vPlan = planDroppedCeiling(pLengthMm: 0, pWidthMm: 0, pHeightMm: 2400, pWantedMm: 2500);
    expect(vPlan.plenumMm, 0);
    expect(vPlan.rows, 0);
    expect(vPlan.hangers, 0);
    expect(vPlan.savedVolumeM3, 0);
  });
}
