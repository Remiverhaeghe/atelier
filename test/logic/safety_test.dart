import 'package:atelier/logic/guidance.dart';
import 'package:atelier/logic/safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque protection sert, les coupes demandent lunettes et casque', () {
    final vUsed = {for (final vStep in GuideStep.values) ...stepSafety(vStep)};

    expect(vUsed, SafetyCheck.values.toSet());
    expect(stepSafety(GuideStep.cutBaseboards), contains(SafetyCheck.earProtection));
    expect(stepSafety(GuideStep.fixBaseboards).first, SafetyCheck.powerOff);
    expect(stepSafety(GuideStep.acclimatise), isEmpty);
  });
}
