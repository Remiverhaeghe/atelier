import 'package:atelier/logic/aisles.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque article a son rayon', () {
    expect(aisleOf(ShoppingItem.parquetPacks), Aisle.flooring);
    expect(aisleOf(ShoppingItem.cartridges), Aisle.adhesives);
    expect(aisleOf(ShoppingItem.fixingPoints), Aisle.hardware);
    expect(aisleOf(ShoppingItem.rollers), Aisle.paint);
  });

  test('le rayon d\'un article ajouté se lit dans son nom', () {
    expect(aisleOfText('Bois 45 × 145 mm en 450 cm'), Aisle.timber);
    expect(aisleOfText('Sabots de solive'), Aisle.hardware);
    expect(aisleOfText('Sacs de béton prêt à l\'emploi de 35 kg'), Aisle.building);
    expect(aisleOfText('Cartouches de colle D3 ou PU'), Aisle.adhesives);
    expect(aisleOfText('Lampe frontale'), Aisle.other);
  });

  test('magasin saisi d\'abord, puis rayons conseillés dans l\'ordre du parcours', () {
    const vLines = [
      ShoppingLine(item: ShoppingItem.rollers, quantity: 2, unitPrice: null),
      ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 9, unitPrice: null),
      ShoppingLine(item: ShoppingItem.nailBoxes, quantity: 1, unitPrice: null),
    ];

    final vGroups = groupByAisle(vLines, const {'nailBoxes': 'Quincaillerie du coin'});

    expect([for (final vGroup in vGroups) (vGroup.store, vGroup.aisle)], [
      ('Quincaillerie du coin', null),
      ('', Aisle.flooring),
      ('', Aisle.paint),
    ]);
  });
}
