import 'package:atelier/logic/acoustics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloison : deux faces, ni suspente ni sous-couche', () {
    // 4 m sur 2,5 m : 10 m², tour de 13 m
    final vPlan = soundPlan(SoundCase.partition, 10, 13000);
    expect(vPlan.boards, 8);
    expect(vPlan.woolM2, 10);
    expect(vPlan.resilientBandM, 13);
    expect(vPlan.mastic, 3);
    expect((vPlan.hangers, vPlan.underlayM2), (0, 0.0));
  });

  test('plancher de mezzanine : plafond suspendu et sous-couche', () {
    final vPlan = soundPlan(SoundCase.mezzanineFloor, 12, 14000);
    expect(vPlan.boards, 5);
    expect(vPlan.hangers, 17);
    expect(vPlan.underlayM2, closeTo(12.6, 1e-9));
    expect(vPlan.mastic, 2);
  });

  test('surface négative ramenée à zéro', () {
    final vPlan = soundPlan(SoundCase.partition, -3, 0);
    expect((vPlan.boards, vPlan.woolM2, vPlan.mastic), (0, 0.0, 0));
  });
}
