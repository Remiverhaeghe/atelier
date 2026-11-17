import 'package:atelier/logic/rolling_tower.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plafond à 4 m sur base étroite : plancher à 2 m, deux éléments, stabilisateurs', () {
    final vPlan = planTower(pReachMm: 4000, pBase: TowerBase.narrow);
    expect(vPlan.platformMm, 2000);
    expect(vPlan.frames, 2);
    expect(vPlan.totalHeightMm, 3000);
    expect(vPlan.needsStabilisers, isTrue);
    expect(vPlan.tooHigh, isFalse);
  });

  test('le plancher se règle au demi-mètre supérieur, base large sans stabilisateurs', () {
    final vPlan = planTower(pReachMm: 3500, pBase: TowerBase.wide);
    expect(vPlan.platformMm, 1500);
    expect(vPlan.frames, 2);
    expect(vPlan.needsStabilisers, isFalse);
  });

  test('assez bas pour rester au sol', () {
    final vPlan = planTower(pReachMm: 1800, pBase: TowerBase.wide);
    expect(vPlan.platformMm, 0);
    expect(vPlan.frames, 1);
  });

  test('dehors, le vent impose les stabilisateurs plus tôt', () {
    expect(planTower(pReachMm: 5500, pBase: TowerBase.wide).needsStabilisers, isFalse);
    expect(
      planTower(pReachMm: 5500, pBase: TowerBase.wide, pOutdoor: true).needsStabilisers,
      isTrue,
    );
  });

  test('trop haut dehors pour un montage soi-même', () {
    expect(planTower(pReachMm: 11000, pBase: TowerBase.wide).tooHigh, isFalse);
    expect(planTower(pReachMm: 11000, pBase: TowerBase.wide, pOutdoor: true).tooHigh, isTrue);
  });
}
