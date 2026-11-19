import 'package:atelier/logic/wood_finish.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('10 m² de lasure en trois couches : 2,5 L en tout, un pot de 2,5 L', () {
    final vPlan = planFinish(WoodFinish.stain, 10);
    expect(vPlan.litres, closeTo(2.5, 1e-9));
    expect(vPlan.pots, {2.5: 1});
    // Deux attentes de 6 h entre trois couches
    expect(vPlan.waitHours, 12);
  });

  test('12,5 m² d\'huile en deux couches : deux pots de 1 L plutôt qu\'un de 2,5 L', () {
    final vPlan = planFinish(WoodFinish.oil, 12.5);
    expect(vPlan.litres, closeTo(12.5 * 2 / 15, 1e-9));
    expect(vPlan.pots, {1.0: 2});
    expect(vPlan.waitHours, 24);
  });

  test('surface nulle ou négative : rien à acheter', () {
    expect(planFinish(WoodFinish.wax, 0).pots, isEmpty);
    expect(planFinish(WoodFinish.wax, -3).litres, 0);
  });

  test('25 m² de peinture en deux couches : un pot de 5 L', () {
    expect(planFinish(WoodFinish.microporousPaint, 25).pots, {5.0: 1});
  });

  test('chaque usage a ses finitions', () {
    expect(finishesFor(FinishUse.floor), [WoodFinish.floorVarnish, WoodFinish.oil]);
    expect(finishesFor(FinishUse.outdoor), isNot(contains(WoodFinish.wax)));
    expect(finishesFor(FinishUse.outdoor), isNot(contains(WoodFinish.varnish)));
    expect(finishesFor(FinishUse.furniture), isNot(contains(WoodFinish.floorVarnish)));
    expect(finishesFor(FinishUse.furniture), contains(WoodFinish.wax));
  });

  test('vernis, vitrificateur et peinture forment un film ; lasure, huile et cire non', () {
    expect(WoodFinish.values.where((pFinish) => pFinish.film), [
      WoodFinish.varnish,
      WoodFinish.floorVarnish,
      WoodFinish.microporousPaint,
    ]);
  });
}
