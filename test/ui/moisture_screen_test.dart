import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/moisture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('humidité : deux relevés de chape, jours restants, puis feu vert', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()..saved = [const Worksite(id: 'w', name: 'Maison')];
    final vController = WorksitesController(vStorage);
    await vController.load();
    var vToday = DateTime(2026, 11, 10);
    Future<void> vShow() => pTester.pumpWidget(
      localized(MoistureScreen(controller: vController, worksiteId: 'w', today: vToday)),
    );
    Future<void> vNote(String pValue) async {
      await pTester.tap(find.text('Noter un relevé'));
      await pTester.pumpAndSettle();
      await pTester.enterText(find.byType(TextField), pValue);
      await pTester.tap(find.text('Enregistrer'));
      await pTester.pumpAndSettle();
    }

    await vShow();
    expect(find.textContaining('Notez les relevés'), findsOneWidget);
    await vNote('3');
    expect(find.textContaining('attendez de passer sous 2 %'), findsOneWidget);

    vToday = DateTime(2026, 11, 14);
    await vShow();
    await vNote('2,6');
    expect(find.text('Encore environ 6 jours au rythme actuel'), findsOneWidget);
    expect(vStorage.saved.single.moisture, hasLength(2));

    vToday = DateTime(2026, 11, 20);
    await vShow();
    await vNote('1,9');
    expect(find.text('1,9 % : vous pouvez poser'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer').first);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.moisture, hasLength(2));
  });
}
