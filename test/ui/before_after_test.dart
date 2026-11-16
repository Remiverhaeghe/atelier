import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/before_after.dart';
import 'package:atelier/ui/journal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('photo d\'avant ajoutée, puis comparaison au doigt', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [rectangleRoom()],
          journal: const [
            JournalEntry(
              id: 'j',
              roomId: 'salon',
              day: '2026-11-16',
              title: 'Peinture',
              photoPath: '/photos/apres.jpg',
            ),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        JournalScreen(
          controller: vController,
          worksiteId: 'w',
          photos: (pId) async => '/photos/$pId.jpg',
        ),
      ),
    );
    expect(find.text('Avant / après'), findsNothing);

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Photo d\'avant'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.journal.single.beforePath, '/photos/j-avant.jpg');

    await pTester.tap(find.text('Avant / après'));
    await pTester.pumpAndSettle();
    expect(find.byType(BeforeAfterScreen), findsOneWidget);
    expect(find.text('Avant'), findsOneWidget);
    await pTester.drag(find.byType(BeforeAfterScreen), const Offset(-200, 0));
    await pTester.pump();
    expect(find.text('Après'), findsOneWidget);
  });
}
