import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/offcuts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('une chute notée trouve sa place, puis se supprime', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(OffcutsScreen(controller: vController, worksiteId: 'w')));
    expect(find.textContaining('Gardez les chutes'), findsOneWidget);

    await pTester.tap(find.text('Noter une chute'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Longueur invalide.'), findsOneWidget);
    await pTester.enterText(find.byType(TextField), '200');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(vStorage.saved.single.offcuts.single.lengthMm, 2000);
    expect(find.text('Où les réutiliser'), findsOneWidget);
    expect(find.textContaining('Salon, rangée'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.offcuts, isEmpty);
  });
}
