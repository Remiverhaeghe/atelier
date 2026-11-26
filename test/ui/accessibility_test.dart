import 'package:atelier/app.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/day_log_screen.dart';
import 'package:atelier/ui/quick_walls_screen.dart';
import 'package:atelier/ui/tiling_calculator.dart';
import 'package:atelier/ui/workshop_mode_screen.dart';
import 'package:atelier/ui/worksite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

/// Règles d'accessibilité d'Android et de Flutter : boutons nommés pour TalkBack, cibles d'au
/// moins 48 dp, texte lisible sur son fond.
Future<void> _checkGuidelines(WidgetTester pTester) async {
  final vHandle = pTester.ensureSemantics();
  await expectLater(pTester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(pTester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(pTester, meetsGuideline(textContrastGuideline));
  vHandle.dispose();
}

void main() {
  testWidgets('accueil vide', (pTester) async {
    final vController = WorksitesController(MemoryStorage());
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('chantier avec une pièce', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(
      localized(
        WorksiteScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 17)),
      ),
    );
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('calculs', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  /// Les écrans récents tiennent aussi avec le texte de l'appareil agrandi au maximum (200 %).
  Future<void> checkBigText(WidgetTester pTester, Widget pScreen) async {
    tallScreen(pTester);
    pTester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(pTester.platformDispatcher.clearTextScaleFactorTestValue);
    await pTester.pumpWidget(localized(pScreen));
    await pTester.pumpAndSettle();
    expect(pTester.takeException(), isNull);
    await pTester.pumpWidget(const SizedBox());
  }

  Future<WorksitesController> vSite() async {
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(
            id: 'w',
            name: 'Maison démo',
            rooms: [rectangleRoom()],
            timeEntries: const [
              TimeEntry(roomId: 'salon', phase: WorkPhase.walls, minutes: 90, day: '2026-11-15'),
            ],
          ),
        ],
    );
    await vController.load();

    return vController;
  }

  testWidgets('journal quotidien', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(DayLogScreen(controller: await vSite(), worksiteId: 'w')));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('carrelage et mosaïque', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(TilingCalculator(rooms: [rectangleRoom()])));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('mode atelier', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        WorkshopModeScreen(
          title: 'Mur',
          steps: const ['Sous-couche', 'Peinture'],
          awake: (_) async {},
        ),
      ),
    );
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
    await pTester.pumpWidget(const SizedBox());
  });

  testWidgets('saisie rapide des murs', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(QuickWallsScreen(room: rectangleRoom())));
    await pTester.pumpAndSettle();
    await _checkGuidelines(pTester);
  });

  testWidgets('texte à 200 % : journal, carrelage, mode atelier, saisie des murs', (pTester) async {
    await checkBigText(pTester, DayLogScreen(controller: await vSite(), worksiteId: 'w'));
    await checkBigText(pTester, TilingCalculator(rooms: [rectangleRoom()]));
    await checkBigText(
      pTester,
      WorkshopModeScreen(title: 'Mur', steps: const ['Sous-couche'], awake: (_) async {}),
    );
    await checkBigText(pTester, QuickWallsScreen(room: rectangleRoom()));
  });
}
