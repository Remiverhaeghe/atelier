import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/worksite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('les tuiles de la maison ouvrent chaque écran d\'un geste', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(
      localized(
        WorksiteScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 16)),
      ),
    );

    for (final (vTile, vTitle) in [
      ('Surface habitable', 'Surface habitable'),
      ('Carnet de la maison', 'Carnet de la maison'),
      ('Temps passé', 'Temps passé'),
      ('Plexis à remplacer', 'Plexis à remplacer'),
      ('Chutes', 'Chutes'),
      ('Bilan du chantier', 'Bilan du chantier'),
      ('Plan de la maison', 'Plan de la maison'),
    ]) {
      await pTester.tap(find.byTooltip(vTile));
      await pTester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(vTitle)),
        findsOneWidget,
        reason: vTile,
      );
      await pTester.pageBack();
      await pTester.pumpAndSettle();
    }
  });
}
