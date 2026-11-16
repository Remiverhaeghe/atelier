import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/time_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('chrono lancé puis arrêté, temps ajouté à la main', (pTester) async {
    tallScreen(pTester);
    var vNow = DateTime(2026, 11, 16, 9);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(TimeScreen(controller: vController, worksiteId: 'w', now: () => vNow)),
    );

    await pTester.tap(find.text('Lancer le chrono'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.timer, isNotNull);

    vNow = vNow.add(const Duration(minutes: 95));
    await pTester.pump(const Duration(seconds: 31));
    expect(find.text('1 h 35'), findsOneWidget);
    await pTester.tap(find.text('Arrêter'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.timer, isNull);
    expect(vStorage.saved.single.timeEntries.single.minutes, 95);
    expect(find.text('1 h 35 sur le chantier'), findsOneWidget);

    await pTester.tap(find.byType(ExpansionTile));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byTooltip('Ajouter du temps').first);
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), '25');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.timeEntries, hasLength(2));
    expect(find.text('2 h sur le chantier'), findsOneWidget);
  });
}
