import 'dart:io';

import 'package:atelier/app.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory vFolder;
  late WorksitesController vController;

  setUp(() {
    vFolder = Directory.systemTemp.createTempSync('atelier_');
    vController = WorksitesController(WorksiteStore(File('${vFolder.path}/chantiers.json')));
  });
  tearDown(() => vFolder.deleteSync(recursive: true));

  testWidgets("l'application s'ouvre sur la liste des chantiers, vide", (pTester) async {
    await pTester.runAsync(vController.load);
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    expect(find.text('Mes chantiers'), findsOneWidget);
    expect(find.textContaining('Aucun chantier'), findsOneWidget);
  });

  testWidgets('on crée un chantier, une pièce et ses quatre murs', (pTester) async {
    await pTester.runAsync(vController.load);
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Nouveau chantier'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), 'Maison');
    await pTester.runAsync(() async {
      await pTester.tap(find.text('Enregistrer'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Nouvelle pièce'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), 'Salon');
    await pTester.runAsync(() async {
      await pTester.tap(find.text('Enregistrer'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await pTester.pumpAndSettle();

    for (final vLength in ['400', '300', '400', '300']) {
      await pTester.tap(find.text('Ajouter un mur'));
      await pTester.pumpAndSettle();
      await pTester.enterText(find.byType(TextField).first, vLength);
      await pTester.runAsync(() async {
        await pTester.tap(find.text('Enregistrer'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await pTester.pumpAndSettle();
    }

    expect(find.text('Mur 4'), findsOneWidget);
    expect(find.textContaining('les mesures sont cohérentes'), findsOneWidget);
    expect(find.textContaining('12,00 m²'), findsWidgets);
    expect(vController.worksites.single.rooms.single.walls, hasLength(4));
  });
}
