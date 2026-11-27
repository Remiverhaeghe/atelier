import 'package:atelier/logic/purchase_check.dart';
import 'package:atelier/logic/right_tool.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('le stock déjà là est compté avec sa valeur quand les prix sont saisis', () {
    final vSite = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [rectangleRoom()],
      stock: {ShoppingItem.baseboardBars.name: 3},
      prices: {ShoppingItem.baseboardBars.name: 5},
    );
    final vCheck = purchaseCheck(vSite);

    expect((vCheck.stockLines, vCheck.stockUnits, vCheck.stockValueEuros), (1, 3, 15.0));
  });

  test('sans stock et sur un petit chantier, rien à signaler', () {
    final vCheck = purchaseCheck(Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]));

    expect(vCheck.stockLines, 0);
    expect(vCheck.tools, isEmpty);
    expect(vCheck.toolSavingEuros, 0);
  });

  test('beaucoup de plinthes à l\'onglet : louer la scie coûte moins cher que l\'acheter', () {
    final vSite = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [for (var vIndex = 0; vIndex < 8; vIndex++) rectangleRoom().copyWith(id: 'p$vIndex')],
    );
    final vTool = purchaseCheck(
      vSite,
    ).tools.singleWhere((pTool) => pTool.task == ToolTask.mitreCuts);

    expect(vTool.choice, ToolChoice.rent);
    expect(vTool.days, greaterThanOrEqualTo(3));
    expect(vTool.savingEuros, PowerTool.mitreSaw.buyEuros - vTool.chosenEuros);
    expect(vTool.savingEuros, greaterThan(0));
  });
}
