import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/shopping_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('deux magasins, leurs prix, puis le panier panaché', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(ShoppingScreen(controller: vController, worksiteId: 'w')));

    await pTester.tap(find.byTooltip('Comparer les magasins'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Ajoutez deux magasins'), findsOneWidget);

    for (final vStore in ['Brico Nord', 'Négoce Sud']) {
      await pTester.tap(find.text('Ajouter un magasin'));
      await pTester.pumpAndSettle();
      await pTester.enterText(find.byType(TextField), vStore);
      await pTester.tap(find.text('Enregistrer'));
      await pTester.pumpAndSettle();
    }
    expect(vStorage.saved.single.storePrices.keys, containsAll(['Brico Nord', 'Négoce Sud']));

    await pTester.tap(find.text('Brico Nord'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField).first, '25');
    await pTester.testTextInput.receiveAction(TextInputAction.done);
    await pTester.pumpAndSettle();

    expect(vStorage.saved.single.storePrices['Brico Nord']!.values, [25.0]);
    expect(find.text('Panier panaché le moins cher'), findsOneWidget);
  });
}
