import 'package:atelier/logic/warranties.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/warranties_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('garanties : fin proche signalée, nouvelle garantie notée', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        const Worksite(
          id: 'w',
          name: 'Maison',
          warranties: [
            Warranty(id: 'c', label: 'Chaudière', kind: WarrantyKind.biennial, start: '2025-01-10'),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage, pNewId: () => 'n');
    await vController.load();
    await pTester.pumpWidget(
      localized(
        WarrantiesScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 17)),
      ),
    );
    expect(find.textContaining('Jusqu\'au 2027-01-10'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);

    await pTester.tap(find.text('Noter une garantie'));
    await pTester.pumpAndSettle();
    await pTester.enterText(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first,
      'Volets roulants',
    );
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.warranties.last.end, DateTime(2028, 11, 17));
  });
}
