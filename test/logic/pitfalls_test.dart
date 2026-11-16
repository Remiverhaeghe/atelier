import 'package:atelier/logic/guidance.dart';
import 'package:atelier/logic/pitfalls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque étape a au moins un piège, et chaque piège sert', () {
    final vUsed = <Pitfall>{};
    for (final vStep in GuideStep.values) {
      final vPitfalls = stepPitfalls(vStep);
      expect(vPitfalls, isNotEmpty, reason: vStep.name);
      vUsed.addAll(vPitfalls);
    }
    expect(vUsed, Pitfall.values.toSet());
    expect(stepPitfalls(GuideStep.firstRow).first, Pitfall.noExpansionGap);
  });

  test('prochaine étape à faire', () {
    const vSteps = [GuideStep.acclimatise, GuideStep.prepareFloor, GuideStep.firstRow];

    expect(nextStep(vSteps, const []), GuideStep.acclimatise);
    expect(nextStep(vSteps, const ['acclimatise']), GuideStep.prepareFloor);
    expect(nextStep(vSteps, const ['acclimatise', 'prepareFloor', 'firstRow']), isNull);
  });
}
