import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/store_compare.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

const _lines = [
  ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 6, unitPrice: null),
  ShoppingLine(item: ShoppingItem.cartridges, quantity: 2, unitPrice: null),
  ShoppingLine(item: ShoppingItem.baseboardBars, quantity: 0, unitPrice: null),
];

const _prices = {
  'Magasin A': {'parquetPacks': 30.0, 'cartridges': 8.0},
  'Magasin B': {'parquetPacks': 28.0, 'cartridges': 10.0},
  'Magasin C': {'parquetPacks': 20.0},
};

void main() {
  test('totaux : magasins complets d\'abord, du moins cher au plus cher', () {
    final vTotals = storeTotals(_lines, _prices);

    expect(vTotals.map((pTotal) => pTotal.store), ['Magasin B', 'Magasin A', 'Magasin C']);
    expect(vTotals.first.total, 188);
    expect(vTotals[1].total, 196);
    expect(vTotals.last.missing, 1);
  });

  test('panier panaché : chaque article là où il est le moins cher', () {
    final vBasket = bestBasket(_lines, _prices);

    expect(vBasket.storeOf, {'parquetPacks': 'Magasin C', 'cartridges': 'Magasin A'});
    expect(vBasket.total, 136);
    expect(vBasket.missing, 0);
    expect(bestBasket(_lines, const {}).missing, 2);
  });

  test('les prix des magasins s\'enregistrent avec le chantier', () {
    const vWorksite = Worksite(id: 'w', name: 'Maison', storePrices: _prices);
    final vBack = Worksite.fromJson(vWorksite.toJson());

    expect(vBack.storePrices, _prices);
    expect(const Worksite(id: 'w', name: 'M').toJson().containsKey('storePrices'), isFalse);
  });
}
