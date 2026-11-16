import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('recherche : pièce, référence du carnet et calcul, sans accent', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(
            id: 'w',
            name: 'Maison démo',
            rooms: [rectangleRoom()],
            journal: const [
              JournalEntry(
                id: 'j',
                roomId: 'salon',
                day: '2026-10-02',
                title: 'Peinture des murs',
                reference: 'TEINTE-0412',
              ),
            ],
          ),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(SearchScreen(controller: vController)));

    await pTester.enterText(find.byType(TextField), 'teinte');
    await pTester.pump();
    expect(find.text('Peinture des murs'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), 'demo');
    await pTester.pump();
    // Le chantier, et la pièce qui le rappelle en détail
    expect(find.text('Maison démo'), findsNWidgets(2));
    expect(find.text('Salon'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), 'zzz');
    await pTester.pump();
    expect(find.textContaining('Rien ne correspond'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), 'gravats');
    await pTester.pump();
    await pTester.tap(find.text('Gravats et déchetterie'));
    await pTester.pumpAndSettle();
    expect(find.text('Ajouter un déchet'), findsOneWidget);
  });
}
