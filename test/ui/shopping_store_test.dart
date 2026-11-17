import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/shopping_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('en magasin : article coché, magasin et référence gardés', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(ShoppingScreen(controller: vController, worksiteId: 'w')));

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();
    expect(vStorage.saved.single.bought, ['parquetPacks']);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Magasin ou rayon').first,
      'Négoce bois',
    );
    await pTester.testTextInput.receiveAction(TextInputAction.done);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.stores, {'parquetPacks': 'Négoce bois'});
    // Les articles sans magasin se rangent par rayon conseillé
    expect(find.text('Rayon sols'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Référence qui convient').first,
      'Chêne 14 mm',
    );
    await pTester.testTextInput.receiveAction(TextInputAction.done);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.references, {'parquetPacks': 'Chêne 14 mm'});
  });
}
