import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vLines = [
    ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 6, unitPrice: null),
    ShoppingLine(item: ShoppingItem.cartridges, quantity: 2, unitPrice: null),
    ShoppingLine(item: ShoppingItem.baseboardBars, quantity: 8, unitPrice: null),
  ];

  test('regroupées par magasin dans l\'ordre des noms, sans magasin à la fin', () {
    final vGroups = groupByStore(vLines, const {
      'parquetPacks': 'Négoce bois',
      'cartridges': ' Brico rayon colles ',
    });

    expect(vGroups.map((pGroup) => pGroup.store), ['Brico rayon colles', 'Négoce bois', '']);
    expect(vGroups.last.lines.single.item, ShoppingItem.baseboardBars);
    expect(groupByStore(const [], const {}), isEmpty);
  });

  test('cases cochées, magasins et références se relisent', () {
    const vWorksite = Worksite(
      id: 'w',
      name: 'M',
      bought: ['parquetPacks'],
      stores: {'parquetPacks': 'Négoce bois'},
      references: {'parquetPacks': 'Chêne 14 mm'},
    );
    final vBack = Worksite.fromJson(vWorksite.toJson());

    expect(vBack.bought, ['parquetPacks']);
    expect(vBack.stores, {'parquetPacks': 'Négoce bois'});
    expect(vBack.references, {'parquetPacks': 'Chêne 14 mm'});
  });
}
