import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vWorksite = Worksite(
    id: 'maison',
    name: 'Maison',
    rooms: [rectangleRoom(), lShapedRoom()],
    prices: const {'parquetPacks': 30.5, 'baseboardBars': 8},
  );

  test('la liste additionne les pièces, chacune arrondie à l\'unité vendue', () {
    final vLines = shoppingList(vWorksite);
    final vByItem = {for (final vLine in vLines) vLine.item: vLine.quantity};

    expect(vByItem[ShoppingItem.parquetPacks], 14);
    expect(vByItem[ShoppingItem.underlayRolls], 3);
    expect(vByItem[ShoppingItem.baseboardBars], 18);
    expect(vByItem[ShoppingItem.cartridges], 4);
    // Ni colle à parquet ni clous : parquet flottant et plinthes collées
    expect(vByItem.containsKey(ShoppingItem.glueBuckets), isFalse);
    expect(vByItem.containsKey(ShoppingItem.fixingPoints), isFalse);
    expect(vLines.map((pLine) => pLine.item).toList(), [
      ShoppingItem.parquetPacks,
      ShoppingItem.underlayRolls,
      ShoppingItem.baseboardBars,
      ShoppingItem.cartridges,
    ]);
  });

  test('le budget compte les prix connus et signale ceux qui manquent', () {
    final vLines = shoppingList(vWorksite);

    expect(vLines.first.total, closeTo(427, 0.001));
    expect(vLines[1].total, isNull);
    expect(budgetTotal(vLines), closeTo(571, 0.001));
    expect(budgetIncomplete(vLines), isTrue);
  });

  test('coût d\'une pièce', () {
    expect(roomCost(rectangleRoom(), vWorksite.prices), closeTo(247, 0.001));
  });

  test('un chantier vide ne demande rien', () {
    const vEmpty = Worksite(id: 'w', name: 'W');

    expect(shoppingList(vEmpty), isEmpty);
    expect(budgetTotal(const []), 0);
    expect(budgetIncomplete(const []), isFalse);
  });

  test('les prix se relisent depuis le JSON', () {
    final vCopy = Worksite.fromJson(vWorksite.toJson());

    expect(vCopy.prices, {'parquetPacks': 30.5, 'baseboardBars': 8.0});
    expect(Worksite.fromJson({'id': 'w', 'name': 'W'}).prices, isEmpty);
  });

  test('les achats des reprises pas finies suivent leur pièce', () {
    const vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [
        Room(
          id: 'b',
          name: 'Bureau',
          touchUps: [
            TouchUp(id: '1', label: 'Applique', toBuy: 'Applique murale'),
            TouchUp(id: '2', label: 'Grille', donePasses: 1, toBuy: 'Grille'),
          ],
        ),
      ],
    );

    expect(worksitePurchases(vWorksite), [(item: 'Applique murale', room: 'Bureau')]);
  });

  test('stock restant après le chantier : au-delà du besoin, et ce qui ne sert pas', () {
    final vBase = Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]);
    final vNeeded = shoppingList(
      vBase,
    ).firstWhere((pLine) => pLine.item == ShoppingItem.parquetPacks).quantity;
    final vWorksite = vBase.copyWith(stock: {'parquetPacks': vNeeded + 2, 'thresholdBars': 3});
    final vLeft = leftoverStock(vWorksite);
    expect(vLeft[ShoppingItem.parquetPacks], 2);
    expect(vLeft[ShoppingItem.thresholdBars], 3);
    expect(leftoverStock(vBase), isEmpty);
  });
}
