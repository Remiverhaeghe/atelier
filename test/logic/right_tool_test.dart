import 'package:atelier/logic/right_tool.dart';
import 'package:atelier/logic/starter_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quelques planches à scier : la scie à main suffit, déjà dans la caisse', () {
    final vAdvice = adviseTool(ToolTask.cutBoards, 1, pOwnsManual: true);
    expect(vAdvice.choice, ToolChoice.manual);
    expect(vAdvice.budgetEuros, 0);
    final vBuyManual = adviseTool(ToolTask.cutBoards, 2);
    expect(vBuyManual.choice, ToolChoice.manual);
    expect(vBuyManual.budgetEuros, 21);
    expect(ToolTask.cutBoards.manual, StarterTool.handSaw);
  });

  test('peu de jours : on emprunte si on peut, sinon on loue', () {
    expect(adviseTool(ToolTask.drillConcrete, 2, pCanBorrow: true).choice, ToolChoice.borrow);
    final vRent = adviseTool(ToolTask.drillConcrete, 2);
    expect(vRent.choice, ToolChoice.rent);
    expect(vRent.rentEuros, 60);
    expect(vRent.budgetEuros, 60);
    // Le perforateur se rentabilise en quatre jours de location
    expect(vRent.breakEvenDays, 4);
  });

  test('beaucoup de jours : acheter revient moins cher', () {
    final vBuy = adviseTool(ToolTask.drillConcrete, 6, pCanBorrow: true);
    expect(vBuy.choice, ToolChoice.buy);
    expect(vBuy.budgetEuros, 120);
    expect(vBuy.rentEuros, 180);
  });

  test('la ponceuse à parquet se loue, même pour une grande pièce', () {
    expect(adviseTool(ToolTask.sandFloor, 3).choice, ToolChoice.rent);
    // Zéro jour compte pour un
    expect(adviseTool(ToolTask.sandFloor, 0).rentEuros, 60);
  });

  test('chaque outil électrique a un prix d\'achat au-dessus de sa journée de location', () {
    for (final vTool in PowerTool.values) {
      expect(vTool.buyEuros, greaterThan(vTool.dayEuros), reason: vTool.name);
    }
  });
}
