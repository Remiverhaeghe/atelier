import 'package:atelier/logic/loans.dart';
import 'package:atelier/logic/reminders.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/loans_screen.dart';
import 'package:atelier/ui/reminder_alarm.dart';
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

  testWidgets('location : retour, coût, caution, rappel la veille puis annulé', (pTester) async {
    final vAlarm = _Alarm();
    aReminderAlarm = vAlarm;
    addTearDown(() => aReminderAlarm = const SilentAlarm());
    final vStorage = MemoryStorage()..saved = [const Worksite(id: 'w', name: 'Maison')];
    final vController = WorksitesController(vStorage, pNewId: () => 'loc');
    await vController.load();
    await pTester.pumpWidget(
      localized(
        LoansScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 18)),
      ),
    );
    await pTester.tap(find.byTooltip('Louer un outil'));
    await pTester.pumpAndSettle();
    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vFields.at(0), 'Malaxeur');
    await pTester.enterText(vFields.at(1), 'Loueur du coin');
    await pTester.enterText(vFields.at(2), '3');
    await pTester.enterText(vFields.at(3), '150');
    await pTester.enterText(vFields.at(4), '22');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vWorksite = vStorage.saved.single;
    expect(vWorksite.loans.single.returnBy, '2026-11-21');
    expect(vWorksite.reminders.single.dueAt, DateTime(2026, 11, 20, 18));
    expect(vAlarm.scheduled.single.$2, contains('Malaxeur'));
    expect(find.text('Outils loués'), findsOneWidget);
    expect(find.textContaining('Retour le 21/11 · 3 jours · 66 €, caution 150 €'), findsOneWidget);

    await pTester.tap(find.text('Rendu'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.loans, isEmpty);
    expect(vStorage.saved.single.reminders, isEmpty);
    expect(vAlarm.cancelled, ['location-loc']);
  });

  testWidgets('location en retard : jours et coût en plus', (pTester) async {
    final vStorage = MemoryStorage()
      ..saved = [
        const Worksite(
          id: 'w',
          name: 'Maison',
          loans: [
            Loan(
              id: 'b',
              tool: 'Ponceuse à parquet',
              person: '',
              since: '2026-11-14',
              returnBy: '2026-11-15',
              dayEuros: 60,
            ),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        LoansScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 17)),
      ),
    );
    expect(find.textContaining('2 jours de retard : environ 120 € de plus'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });
}

class _Alarm implements ReminderAlarm {
  final scheduled = <(String, String)>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody) async =>
      scheduled.add((pReminder.id, pBody));

  @override
  Future<void> cancel(Reminder pReminder) async => cancelled.add(pReminder.id);
}
