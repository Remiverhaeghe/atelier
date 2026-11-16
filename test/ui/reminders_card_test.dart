import 'package:atelier/logic/reminders.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/reminder_alarm.dart';
import 'package:atelier/ui/reminders_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

/// Alarme qui note ce qu'on lui demande, à la place des notifications Android.
class _FakeAlarm implements ReminderAlarm {
  final scheduled = <String>[];
  final cancelled = <String>[];

  @override
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody) async =>
      scheduled.add('$pTitle : $pBody');

  @override
  Future<void> cancel(Reminder pReminder) async => cancelled.add(pReminder.id);
}

void main() {
  testWidgets('attente lancée pour une pièce, puis prête et retirée', (pTester) async {
    final vAlarm = _FakeAlarm();
    aReminderAlarm = vAlarm;
    addTearDown(() => aReminderAlarm = const SilentAlarm());
    var vWorksite = Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]);
    var vNow = DateTime(2026, 11, 16, 10);
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          RemindersCard(
            worksite: vWorksite,
            now: vNow,
            onChanged: (pNew) => pSetState(() => vWorksite = pNew),
          ),
        ),
      ),
    );
    expect(find.textContaining('Lancez une attente'), findsOneWidget);

    await pTester.tap(find.byTooltip('Lancer une attente'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byType(DropdownButtonFormField<String?>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Salon').last);
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(vWorksite.reminders.single.kind, WaitKind.acclimatise);
    expect(find.text('Acclimatation du parquet, Salon'), findsOneWidget);
    expect(find.text('Encore 48 heures'), findsOneWidget);
    expect(vAlarm.scheduled, ['Attente terminée : Acclimatation du parquet']);

    vNow = DateTime(2026, 11, 18, 11);
    await pTester.pumpWidget(
      localized(
        RemindersCard(worksite: vWorksite, now: vNow, onChanged: (pNew) => vWorksite = pNew),
      ),
    );
    expect(find.text('C\'est prêt'), findsOneWidget);
    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pump();
    expect(vWorksite.reminders, isEmpty);
    expect(vAlarm.cancelled, hasLength(1));
  });
}
