import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('bilan affiché, leçon notée puis retirée', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        const Worksite(
          id: 'w',
          name: 'Maison',
          expenses: [Expense(id: 'e', label: 'Colle', amount: 42.5, date: '2026-11-01')],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(ReviewScreen(controller: vController, worksiteId: 'w')));

    expect(find.text('42,50 €'), findsOneWidget);
    expect(find.text('Aucune chute gardée'), findsOneWidget);

    await pTester.tap(find.text('Noter une leçon'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), 'Commander les plinthes en avance');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.lessons, ['Commander les plinthes en avance']);

    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.lessons, isEmpty);
  });
}
