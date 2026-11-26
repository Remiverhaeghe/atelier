import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/site_mode_screen.dart';
import 'package:atelier/ui/workshop_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('chronomètre en gros, étapes une à une, temps gardé par étape', (pTester) async {
    tallScreen(pTester);
    var vNow = DateTime(2026, 11, 19, 9);
    final vAwake = <bool>[];
    final vDone = <(int, Duration)>[];
    await pTester.pumpWidget(
      localized(
        WorkshopModeScreen(
          title: 'Étagère',
          steps: const ['Tracer', 'Scier', 'Poncer'],
          awake: (pOn) async => vAwake.add(pOn),
          clock: () => vNow,
          onStepDone: (pIndex, pTime) => vDone.add((pIndex, pTime)),
        ),
      ),
    );
    await pTester.pump();
    expect(vAwake, [true]);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Étape 1 sur 3'), findsOneWidget);
    // Boutons assez hauts pour des gants
    expect(
      pTester
          .getSize(
            find.ancestor(
              of: find.text('Démarrer'),
              matching: find.byWidgetPredicate((pWidget) => pWidget is FilledButton),
            ),
          )
          .height,
      greaterThanOrEqualTo(workshopButtonHeight),
    );

    await pTester.tap(find.text('Démarrer'));
    await pTester.pump();
    vNow = vNow.add(const Duration(minutes: 2, seconds: 5));
    await pTester.pump(const Duration(seconds: 1));
    expect(find.text('02:05'), findsOneWidget);

    await pTester.tap(find.text('Fait'));
    await pTester.pump();
    expect(vDone.single, (0, const Duration(minutes: 2, seconds: 5)));
    expect(find.text('Étape 2 sur 3'), findsOneWidget);
    expect(find.text('02:05 sur cette étape'), findsOneWidget);

    await pTester.tap(find.text('Suivante'));
    await pTester.pump();
    expect(find.text('Étape 3 sur 3'), findsOneWidget);
    await pTester.tap(find.text('Précédente'));
    await pTester.pump();
    expect(find.text('Étape 2 sur 3'), findsOneWidget);

    await pTester.tap(find.text('Pause'));
    await pTester.pump();
    await pTester.tap(find.text('Remettre à zéro'));
    await pTester.pump();
    expect(find.text('00:00'), findsOneWidget);

    await pTester.pumpWidget(const SizedBox());
    expect(vAwake, [true, false]);
  });

  testWidgets('sans étape, le mode atelier le dit', (pTester) async {
    await pTester.pumpWidget(
      localized(WorkshopModeScreen(title: 'Vide', steps: const [], awake: (_) async {})),
    );
    await pTester.pump();
    expect(find.textContaining('Aucune étape à suivre'), findsOneWidget);
  });

  testWidgets('depuis le mode chantier, une étape faite finit la reprise', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison démo',
          rooms: [
            rectangleRoom().copyWith(
              touchUps: const [
                TouchUp(id: 'a', label: 'Reboucher la fissure', passes: 2),
                TouchUp(id: 'b', label: 'Déjà fait', donePasses: 1),
              ],
            ),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (_) async {},
          awake: (_) async {},
        ),
      ),
    );
    await pTester.pumpAndSettle();
    await pTester.tap(find.byTooltip('Mode atelier'));
    await pTester.pumpAndSettle();
    expect(find.text('Étape 1 sur 1'), findsOneWidget);
    expect(find.text('Déjà fait'), findsNothing);

    await pTester.tap(find.text('Fait'));
    await pTester.pump();
    expect(find.text('Toutes les étapes sont faites.'), findsOneWidget);
    final vTouchUp = vStorage.saved.single.rooms.single.touchUps.first;
    expect(vTouchUp.done, isTrue);
  });

  testWidgets('séchage lié à l\'étape, et balayage vers l\'étape suivante', (pTester) async {
    tallScreen(pTester);
    var vNow = DateTime(2026, 11, 26, 9);
    await pTester.pumpWidget(
      localized(
        WorkshopModeScreen(
          title: 'Mur',
          steps: const ['Sous-couche', 'Peinture'],
          awake: (_) async {},
          clock: () => vNow,
        ),
      ),
    );
    await pTester.pump();

    await pTester.tap(find.text('1 h'));
    await pTester.pump();
    expect(find.text('Séchage : encore 1:00:00'), findsOneWidget);

    vNow = vNow.add(const Duration(minutes: 20));
    await pTester.pump(const Duration(seconds: 1));
    expect(find.text('Séchage : encore 40:00'), findsWidgets);

    // Un balayage vers la gauche passe à l'étape suivante, sans minuteur dessus
    await pTester.fling(find.text('Sous-couche').first, const Offset(-300, 0), 1000);
    await pTester.pump();
    expect(find.text('Étape 2 sur 2'), findsOneWidget);
    expect(find.text('Minuteur de séchage'), findsOneWidget);

    await pTester.pumpWidget(const SizedBox());
  });
}
