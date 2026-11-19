import 'package:atelier/logic/tool_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prêt quand toutes les vérifications sont cochées', () {
    expect(readyToStart(SafetyTool.circularSaw, {0, 1, 2}), isFalse);
    expect(readyToStart(SafetyTool.circularSaw, {0, 1, 2, 3}), isTrue);
    expect(readyToStart(SafetyTool.ladder, const {}), isFalse);
  });

  test('pied de l\'échelle au quart de la hauteur, environ 75°', () {
    expect(ladderFootMm(3000), 750);
    expect(ladderLengthMm(3000), 3092);
    expect(ladderLengthMm(3000, pStepOff: true), 4092);
  });

  test('les machines qui tournent interdisent les gants amples, sauf la meuleuse', () {
    expect(SafetyTool.circularSaw.noLooseGloves, isTrue);
    expect(SafetyTool.grinder.noLooseGloves, isFalse);
    expect(SafetyTool.grinder.protections, contains(Protection.cutGloves));
    for (final vTool in SafetyTool.values) {
      expect(vTool.protections, isNotEmpty, reason: vTool.name);
      expect(vTool.checks, greaterThan(0), reason: vTool.name);
      expect(vTool.forbidden, greaterThan(0), reason: vTool.name);
    }
    expect(SafetyTool.values.where((pTool) => pTool.noisy), hasLength(3));
  });
}
