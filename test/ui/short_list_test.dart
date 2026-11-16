import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/shopping_texts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vText = AppLocalizationsFr();

  test('liste courte : ce qui reste à acheter, par magasin, sans prix', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison démo',
      rooms: [rectangleRoom()],
      prices: const {'parquetPacks': 30, 'underlayRolls': 20},
      bought: const ['parquetPacks'],
      stores: const {'underlayRolls': 'Brico démo'},
      references: const {'underlayRolls': 'SC-3MM'},
    );
    final vShort = shortShoppingText(vText, vWorksite);

    expect(vShort, startsWith('À acheter pour Maison démo :'));
    expect(vShort, contains('Brico démo'));
    expect(vShort, contains('(SC-3MM)'));
    expect(vShort, isNot(contains('€')));
    expect(vShort, isNot(contains(itemLabel(vText, ShoppingItem.parquetPacks))));
  });

  test('tout acheté', () {
    final vWorksite = Worksite(id: 'w', name: 'Garage', rooms: [rectangleRoom()]);
    final vAll = vWorksite.copyWith(
      bought: [for (final vLine in shoppingList(vWorksite)) vLine.item.name],
    );
    expect(shortShoppingText(vText, vAll), endsWith('Tout est acheté.'));
  });
}
