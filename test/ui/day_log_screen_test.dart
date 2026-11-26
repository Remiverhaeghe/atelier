import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/day_log_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('une ligne par jour : note du jour, heures du chronomètre, photo', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [rectangleRoom()],
          timeEntries: const [
            TimeEntry(roomId: 'salon', phase: WorkPhase.walls, minutes: 90, day: '2026-11-15'),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        DayLogScreen(
          controller: vController,
          worksiteId: 'w',
          photos: (pId) async => '/photos/$pId.jpg',
          now: () => DateTime(2026, 11, 16),
        ),
      ),
    );

    expect(find.textContaining('2026-11-15'), findsOneWidget);

    await pTester.tap(find.text('Noter aujourd\'hui'));
    await pTester.pumpAndSettle();
    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vFields.at(0), 'Sous-couche des murs');
    await pTester.enterText(vFields.at(1), '2,5');
    await pTester.tap(find.text('Photo du jour'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vNote = vStorage.saved.single.dayNotes.single;
    expect((vNote.day, vNote.minutes, vNote.done), ('2026-11-16', 150, 'Sous-couche des murs'));
    expect(vNote.photoPath, '/photos/jour-2026-11-16.jpg');
    expect(find.textContaining('2026-11-16 · 2 h 30'), findsOneWidget);
  });
}
