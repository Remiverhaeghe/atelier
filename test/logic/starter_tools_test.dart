import 'package:atelier/logic/starter_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rien dans la caisse : tout l\'indispensable manque', () {
    final vBudget = missingTools(const {}, ToolTier.essential);
    final vEssential = StarterTool.values.where((pTool) => pTool.tier == ToolTier.essential);
    expect(vBudget.count, vEssential.length);
    expect(vBudget.minEuros, vEssential.fold<int>(0, (pSum, pTool) => pSum + pTool.minEuros));
    expect(vBudget.maxEuros, greaterThan(vBudget.minEuros));
  });

  test('ce qu\'on a déjà ne compte plus', () {
    final vBefore = missingTools(const {}, ToolTier.essential);
    final vAfter = missingTools({StarterTool.drillDriver, StarterTool.tape}, ToolTier.essential);
    expect(vAfter.count, vBefore.count - 2);
    expect(vAfter.minEuros, vBefore.minEuros - 60 - 8);
    expect(vAfter.maxEuros, vBefore.maxEuros - 150 - 20);
  });

  test('tout est là : rien à acheter', () {
    final vBudget = missingTools(StarterTool.values.toSet(), ToolTier.next);
    expect(vBudget, (count: 0, minEuros: 0, maxEuros: 0));
  });

  test('chaque outil a une fourchette de prix qui tient debout', () {
    for (final vTool in StarterTool.values) {
      expect(vTool.minEuros, lessThanOrEqualTo(vTool.maxEuros), reason: vTool.name);
    }
  });
}
