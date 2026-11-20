import 'package:atelier/logic/diy_or_pro.dart';
import 'package:atelier/logic/starter_tools.dart';
import 'package:atelier/logic/trades.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un débutant met deux à trois fois le temps d\'un pro', () {
    expect(beginnerHours(Trade.paint), (minHours: 16, maxHours: 24));
    for (final vTrade in Trade.values) {
      final vHours = beginnerHours(vTrade);
      expect(vHours.minHours, (vTrade.proHours * beginnerFactor).ceil(), reason: vTrade.name);
      expect(vHours.maxHours, greaterThan(vHours.minHours), reason: vTrade.name);
    }
  });

  test('rien dans la caisse : tout est à acheter, la location à part', () {
    final vBudget = tradeBudget(Trade.tiling, const {});
    // Mètre, crayon, niveau, raclette, lunettes, peigne et carrelette ; le malaxeur se loue
    expect(vBudget.toBuy, 7);
    expect(vBudget.buyMinEuros, 8 + 2 + 10 + 8 + 5 + 8 + 40);
    expect(vBudget.buyMaxEuros, 20 + 6 + 30 + 20 + 15 + 20 + 120);
    expect(vBudget.toRent, 1);
    expect((vBudget.rentMinEuros, vBudget.rentMaxEuros), (15, 30));
  });

  test('les outils déjà là ne comptent plus', () {
    final vBefore = tradeBudget(Trade.electricity, const {});
    final vAfter = tradeBudget(Trade.electricity, {StarterTool.drillDriver, StarterTool.hammer});
    expect(vAfter.toBuy, vBefore.toBuy - 1);
    expect(vAfter.buyMinEuros, vBefore.buyMinEuros - StarterTool.drillDriver.minEuros);
    expect(vAfter.toRent, 0);
  });

  test('travaux rangés du plus facile au plus délicat, sans en oublier', () {
    final vByLevel = tradesByLevel();
    expect(vByLevel.keys, TradeLevel.values);
    expect(vByLevel[TradeLevel.easy], contains(Trade.paint));
    expect(vByLevel[TradeLevel.pro], containsAll([Trade.electricity, Trade.plumbing]));
    expect(vByLevel.values.expand((pList) => pList).toSet(), Trade.values.toSet());
  });

  test('chaque outil propre a une fourchette de prix qui tient debout', () {
    for (final vTool in TradeTool.values) {
      expect(vTool.minEuros, lessThanOrEqualTo(vTool.maxEuros), reason: vTool.name);
    }
    for (final vTrade in Trade.values) {
      expect(vTrade.tools, isNotEmpty, reason: vTrade.name);
    }
  });
}
