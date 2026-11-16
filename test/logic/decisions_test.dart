import 'package:atelier/logic/decisions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque question a au moins deux façons de faire, notées de 1 à 3', () {
    for (final vDecision in Decision.values) {
      expect(optionsFor(vDecision).length, greaterThanOrEqualTo(2));
    }
    for (final vOption in DecisionOption.values) {
      for (final vScore in [vOption.cost, vOption.time, vOption.difficulty]) {
        expect(vScore, inInclusiveRange(1, 3));
      }
    }
  });

  test('la plus simple est celle qui demande le moins d\'effort', () {
    expect(simplestOption(Decision.baseboardFixing), DecisionOption.glueBaseboard);
    expect(simplestOption(Decision.parquetLaying), DecisionOption.floatingParquet);
    expect(simplestOption(Decision.damagedWall), DecisionOption.fillWall);
  });
}
