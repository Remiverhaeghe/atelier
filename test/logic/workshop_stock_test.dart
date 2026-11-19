import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/loans.dart';
import 'package:atelier/logic/offcuts.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/logic/workshop_stock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  // Deux chantiers : le premier demande 4 cartouches de colle à plinthes, le second 3 boîtes de vis
  final vHouse = Worksite(id: 'maison', name: 'Maison', rooms: [rectangleRoom(), lShapedRoom()]);
  const vShed = Worksite(
    id: 'abri',
    name: 'Abri',
    extras: [
      ExtraItem(name: 'Vis 4 × 40', quantity: 3),
      ExtraItem(name: 'Équerres', quantity: 8),
    ],
  );
  const vGlue = StockItem(
    id: 'colle',
    name: 'Colle mastic',
    category: StockCategory.glue,
    quantity: 3,
    minQuantity: 1,
    link: 'cartridges',
  );
  const vScrews = StockItem(
    id: 'vis',
    name: 'vis 4 × 40 ',
    category: StockCategory.screws,
    quantity: 5,
    minQuantity: 2,
  );

  test('le besoin vient de la ligne des courses liée ou des articles du même nom', () {
    expect(worksiteNeed(vHouse, vGlue), 4);
    expect(worksiteNeed(vShed, vGlue), 0);
    expect(worksiteNeed(vShed, vScrews), 3);
    expect(worksiteNeed(vHouse, vScrews), 0);
  });

  test('le stock sert les chantiers dans l\'ordre, le reste est à acheter', () {
    final vAllocations = allocateStock([vGlue, vScrews], [vHouse, vShed]);
    expect(vAllocations, [
      (worksiteId: 'maison', itemId: 'colle', needed: 4, fromStock: 3, toBuy: 1),
      (worksiteId: 'abri', itemId: 'vis', needed: 3, fromStock: 3, toBuy: 0),
    ]);
    expect(projectedQuantity(vGlue, vAllocations), 0);
    expect(projectedQuantity(vScrews, vAllocations), 2);

    final vRestock = restockList([vGlue, vScrews], vAllocations);
    // Colle : remettre au seuil, couvrir la cartouche qui manque, une d'avance
    expect(vRestock.map((pLine) => (pLine.item.id, pLine.toBuy)).toList(), [
      ('colle', 3),
      ('vis', 1),
    ]);
  });

  test('rien à racheter tant que le stock reste au-dessus du seuil', () {
    const vPlenty = StockItem(id: 'p', name: 'Papier de verre', quantity: 10, minQuantity: 2);
    expect(needsRestock(vPlenty), isFalse);
    expect(restockList([vPlenty], const []), isEmpty);
    expect(needsRestock(vPlenty.copyWith(quantity: 2)), isTrue);
    const vNoAlert = StockItem(id: 'n', name: 'Chiffons');
    expect(restockList([vNoAlert], const []).single.toBuy, 1);
  });

  test('réserver passe le stock au chantier et le déduit de ses courses', () {
    final vAllocations = allocateStock([vGlue, vScrews], [vHouse, vShed]);
    final vHouseResult = reserveFor([vGlue, vScrews], vHouse, vAllocations);
    expect(vHouseResult.worksite.stock['cartridges'], 3);
    final vLine = shoppingList(
      vHouseResult.worksite,
    ).firstWhere((pLine) => pLine.item == ShoppingItem.cartridges);
    expect(vLine.quantity, 1);
    expect(vLine.inStock, 3);
    expect(vHouseResult.items.first.quantity, 0);
    expect(vHouseResult.items.last.quantity, 5);

    final vShedResult = reserveFor([vGlue, vScrews], vShed, vAllocations);
    expect(vShedResult.worksite.extras.map((pExtra) => pExtra.name), ['Équerres']);
    expect(vShedResult.items.last.quantity, 2);
  });

  test('réservation partielle : l\'article ajouté garde ce qui manque', () {
    const vFew = StockItem(id: 'vis', name: 'Vis 4 × 40', quantity: 1);
    final vResult = reserveFor([vFew], vShed, allocateStock([vFew], [vShed]));
    expect(vResult.worksite.extras.first.quantity, 2);
    expect(vResult.items.single.quantity, 0);
  });

  test('stock enregistré et relu, fichier abîmé ignoré', () {
    final vJson = stockToJson([vGlue, vScrews]);
    final vRead = stockFromJson(vJson);
    expect(vRead.length, 2);
    expect(vRead.first.link, 'cartridges');
    expect(vRead.first.category, StockCategory.glue);
    expect(vRead.last.link, isNull);
    expect(vRead.last.minQuantity, 2);
    expect(stockFromJson('abîmé'), isEmpty);
    final vOdd = StockItem.fromJson(const {'id': 'x', 'category': 'inconnue'});
    expect(vOdd.category, StockCategory.other);
    expect(vOdd.name, '');
    expect(vGlue.copyWith(clearLink: true).link, isNull);
    expect(vScrews.copyWith(link: 'rollers', name: 'Rouleaux').link, 'rollers');
  });

  test('outils prêtés et chutes de tous les chantiers réunis', () {
    final vWorksites = [
      vHouse.copyWith(
        loans: const [Loan(id: '1', tool: 'Scie', person: 'Paul', since: '2026-10-02')],
        offcuts: const [
          Offcut(id: 'a', material: OffcutMaterial.plank, lengthMm: 600),
          Offcut(id: 'b', material: OffcutMaterial.plank, lengthMm: 400),
        ],
      ),
      vShed.copyWith(
        loans: const [Loan(id: '2', tool: 'Ponceuse', person: 'Léa', since: '2026-09-15')],
        offcuts: const [Offcut(id: 'c', material: OffcutMaterial.baseboard, lengthMm: 900)],
      ),
    ];
    expect(allLoans(vWorksites).map((pLine) => (pLine.worksite, pLine.loan.tool)).toList(), [
      ('Abri', 'Ponceuse'),
      ('Maison', 'Scie'),
    ]);
    final vTotals = offcutTotals(vWorksites);
    expect(vTotals[OffcutMaterial.plank], (count: 2, lengthMm: 1000));
    expect(vTotals[OffcutMaterial.baseboard], (count: 1, lengthMm: 900));
    expect(linkableItems().first, 'parquetPacks');
  });
}
