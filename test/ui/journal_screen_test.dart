import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('travaux notés, photo jointe, référence retrouvée', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        JournalScreen(
          controller: vController,
          worksiteId: 'w',
          photos: (pId) async => '/photos/$pId.jpg',
          now: () => DateTime(2026, 11, 16),
        ),
      ),
    );
    expect(find.textContaining('Rien de noté'), findsOneWidget);

    await pTester.tap(find.text('Noter des travaux'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Indiquez ce qui a été fait'), findsOneWidget);

    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vFields.at(0), 'Peinture des murs');
    await pTester.enterText(vFields.at(2), 'Acrylique mat blanc');
    await pTester.enterText(vFields.at(3), 'TEINTE-0412');
    await pTester.enterText(vFields.at(4), '120');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vEntry = vStorage.saved.single.journal.single;
    expect((vEntry.day, vEntry.cost, vEntry.roomId), ('2026-11-16', 120.0, 'salon'));
    expect(find.text('120,00 € notés'), findsOneWidget);

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Photo de la facture'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.journal.single.invoicePath, startsWith('/photos/'));

    await pTester.enterText(find.byType(TextField).first, 'blanc');
    await pTester.pump();
    expect(find.text('TEINTE-0412'), findsNWidgets(1));
    expect(find.textContaining('Salon, le 2026-11-16'), findsOneWidget);

    expect(
      journalText(AppLocalizationsFr(), vStorage.saved.single),
      contains('- 2026-11-16 : Peinture des murs, Acrylique mat blanc (TEINTE-0412), 120,00 €'),
    );
  });

  testWidgets('une entrée se supprime', (pTester) async {
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [rectangleRoom()],
          journal: const [JournalEntry(id: 'j', roomId: 'salon', day: '2026-01-01', title: 'Joints')],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(JournalScreen(controller: vController, worksiteId: 'w')));

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.journal, isEmpty);
  });
}
