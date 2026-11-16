import 'package:atelier/logic/kitchen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('linéaire rempli avec le moins de meubles, le reste en fileur', () {
    final vRun = fillRun(2730);
    expect(vRun.modules.fold(0, (pSum, pModule) => pSum + pModule) + vRun.fillerMm, 2730);
    expect(vRun.fillerMm, 30);
    expect(vRun.modules, hasLength(3));
    expect(fillRun(600).modules, [600]);
    expect(fillRun(250).fillerMm, 250);
    expect(fillRun(-10).modules, isEmpty);
  });

  test('plans de travail par linéaire', () {
    expect(worktopsFor([2400, 0, 3200]), [2460, 3650]);
    expect(worktopsFor([5000]), [4100, 2460]);
  });

  test('hauteurs selon la taille et la plaque', () {
    expect(kitchenHeights(1800), (worktopMm: 950, wallUnitsMm: 1500, hoodMm: 1600));
    expect(kitchenHeights(1650, pGas: true).hoodMm, 880 + 750);
  });
}
