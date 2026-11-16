import 'package:atelier/logic/loans.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/loans_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('prêts : ajout, ancien prêt signalé, retour', (pTester) async {
    final vStorage = MemoryStorage()
      ..saved = [
        const Worksite(
          id: 'w',
          name: 'Maison',
          loans: [Loan(id: 'a', tool: 'Ponceuse', person: 'Voisin', since: '2026-10-30')],
        ),
      ];
    final vController = WorksitesController(vStorage, pNewId: () => 'nouveau');
    await vController.load();
    await pTester.pumpWidget(
      localized(
        LoansScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 17)),
      ),
    );
    expect(find.text('Voisin, depuis 18 jours'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);

    await pTester.tap(find.text('Prêter un outil'));
    await pTester.pumpAndSettle();
    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vFields.at(0), 'Scie sauteuse');
    await pTester.enterText(vFields.at(1), 'Collègue');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Collègue, aujourd\'hui'), findsOneWidget);

    await pTester.tap(find.text('Rendu').first);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.loans.single.tool, 'Scie sauteuse');
  });
}
