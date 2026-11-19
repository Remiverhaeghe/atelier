import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/logic/challenges.dart';
import 'package:atelier/logic/mistakes.dart';
import 'package:atelier/logic/reminders.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/settings_controller.dart';
import 'package:atelier/storage/settings_store.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/challenges_screen.dart';
import 'package:atelier/ui/mistakes_screen.dart';
import 'package:atelier/ui/noise_screen.dart';
import 'package:atelier/ui/reminder_alarm.dart';
import 'package:atelier/ui/reminders_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

/// Réglages gardés en mémoire, pour vérifier ce que l'écran enregistre.
class _MemorySettings implements SettingsStorage {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings pSettings) async => saved = pSettings;
}

/// Alarme qui note le texte des notifications demandées.
class _NotedAlarm implements ReminderAlarm {
  final bodies = <String>[];

  @override
  Future<void> schedule(Reminder pReminder, String pTitle, String pBody) async =>
      bodies.add(pBody);

  @override
  Future<void> cancel(Reminder pReminder) async {}
}

void main() {
  testWidgets('je me suis trompé : coulure de vernis, attente et geste à revoir', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Je me suis trompé');
    await pTester.tap(find.text('Je me suis trompé'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Coulure de vernis'));
    await pTester.pumpAndSettle();

    expect(find.text('Attendre environ 24 h avant de reprendre'), findsOneWidget);
    expect(find.text('Se répare'), findsOneWidget);
    expect(find.text('Revoir le geste : Poncer'), findsOneWidget);
  });

  testWidgets('chaque raté a autant d\'étapes que sa logique en annonce', (pTester) async {
    tallScreen(pTester);
    for (final vMistake in Mistake.values) {
      await pTester.pumpWidget(localized(MistakeScreen(mistake: vMistake)));
      expect(find.textContaining(RegExp(r'^\d\. ')), findsNWidgets(vMistake.steps));
    }
  });

  testWidgets('bruit : horaires du jour et prochaine plage à l\'heure du déjeuner', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(NoiseScreen(now: DateTime(2026, 11, 19, 13))));
    expect(find.text('8 h 30 à 12 h'), findsOneWidget);
    expect(find.text('10 h à 12 h'), findsOneWidget);
    expect(find.text('En ce moment : silence. Prochaine plage : aujourd\'hui à 14 h 30'), findsOneWidget);

    await pTester.pumpWidget(localized(NoiseScreen(now: DateTime(2026, 11, 21, 10, 15))));
    expect(find.text('En ce moment : travaux bruyants tolérés jusqu\'à 12 h'), findsOneWidget);
  });

  testWidgets('rappel « outil bruyant le week-end » posé avant la plage du samedi', (pTester) async {
    final vAlarm = _NotedAlarm();
    aReminderAlarm = vAlarm;
    addTearDown(() => aReminderAlarm = const SilentAlarm());
    var vWorksite = Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]);
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          RemindersCard(
            worksite: vWorksite,
            now: DateTime(2026, 11, 19, 10),
            onChanged: (pNew) => pSetState(() => vWorksite = pNew),
          ),
        ),
      ),
    );
    await pTester.tap(find.byTooltip('Lancer une attente'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byType(DropdownButtonFormField<WaitKind>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Outil bruyant le week-end').last);
    await pTester.pumpAndSettle();
    expect(find.text('Rappel samedi à 8 h 45'), findsOneWidget);
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(vWorksite.reminders.single.kind, WaitKind.noisyWeekend);
    expect(vWorksite.reminders.single.dueAt, DateTime(2026, 11, 21, 8, 45));
    expect(vAlarm.bodies.single, startsWith('Outil bruyant ce week-end'));
  });

  testWidgets('défi réussi : compteur, puis badge discret', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ChallengesScreen()));
    expect(find.text('Pas encore essayé'), findsNWidgets(Challenge.values.length));
    expect(find.byTooltip('Premier défi réussi'), findsNothing);

    await pTester.tap(find.text('À refaire').first);
    await pTester.pump();
    await pTester.tap(find.text('Réussi').first);
    await pTester.pump();
    expect(find.text('Réussi 1 fois, essayé 2 fois'), findsOneWidget);
    expect(find.byTooltip('Premier défi réussi'), findsOneWidget);
  });

  testWidgets('avec les réglages, le carnet des défis est enregistré', (pTester) async {
    tallScreen(pTester);
    final vStore = _MemorySettings();
    final vSettings = SettingsController(vStore);
    await pTester.pumpWidget(localized(ChallengesScreen(settings: vSettings)));
    expect(find.textContaining('pas gardé'), findsNothing);

    await pTester.tap(find.text('Réussi').first);
    await pTester.pumpAndSettle();
    expect(vStore.saved.challenges, {Challenge.squareCut: (attempts: 1, successes: 1)});
    expect(find.text('Réussi 1 fois, essayé 1 fois'), findsOneWidget);
  });
}
