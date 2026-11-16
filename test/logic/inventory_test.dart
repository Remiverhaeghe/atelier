import 'package:atelier/logic/goals.dart';
import 'package:atelier/logic/guidance.dart';
import 'package:atelier/logic/inventory.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vRoom = rectangleRoom();

  test('sans inventaire, rien ne manque ; sinon les outils absents de la pièce', () {
    expect(missingTools(vRoom, const []), isEmpty);

    final vOwned = [for (final vTool in Tool.values) vTool.name]..remove(Tool.miterSaw.name);
    expect(missingTools(vRoom, vOwned), [Tool.miterSaw]);
    expect(worksiteMissingTools(Worksite(id: 'w', name: 'M', rooms: [vRoom], ownedTools: vOwned)), [
      Tool.miterSaw,
    ]);
  });

  test('cocher et décocher un outil garde l\'ordre des outils', () {
    final vOwned = toggleTool(toggleTool(const [], Tool.level, true), Tool.tapeMeasure, true);

    expect(vOwned, [Tool.tapeMeasure.name, Tool.level.name]);
    expect(toggleTool(vOwned, Tool.level, false), [Tool.tapeMeasure.name]);
  });

  test('le stock est déduit de ce qu\'il faut acheter et du budget', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'M',
      rooms: [vRoom],
      stock: const {'parquetPacks': 2, 'underlayRolls': 9},
      prices: const {'parquetPacks': 30, 'baseboardBars': 6, 'cartridges': 8},
    );
    final vLines = {for (final vLine in shoppingList(vWorksite)) vLine.item: vLine};

    expect(vLines[ShoppingItem.parquetPacks]!.quantity, 4);
    expect(vLines[ShoppingItem.parquetPacks]!.inStock, 2);
    // Tout est en stock : rien à acheter, le prix manquant ne compte plus
    expect(vLines[ShoppingItem.underlayRolls]!.quantity, 0);
    expect(vLines[ShoppingItem.underlayRolls]!.inStock, 1);
    expect(budgetIncomplete(vLines.values.toList()), isFalse);
    expect(
      budgetTotal(vLines.values.toList()),
      4 * 30 +
          vLines[ShoppingItem.baseboardBars]!.quantity * 6 +
          vLines[ShoppingItem.cartridges]!.quantity * 8,
    );
  });

  test('l\'objectif ne propose pas une pose s\'il manque un outil', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'M',
      rooms: [vRoom],
      ownedTools: [Tool.tapeMeasure.name],
    );

    expect(suggestGoal(vWorksite, DateTime(2026, 11, 16)).items, isEmpty);
    final vBack = Worksite.fromJson(vWorksite.copyWith(stock: const {'parquetPacks': 1}).toJson());
    expect(vBack.ownedTools, [Tool.tapeMeasure.name]);
    expect(vBack.stock, {'parquetPacks': 1});
  });
}
