import 'package:atelier/app.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_storage.dart';

/// Remplit la boîte de dialogue ouverte et l'enregistre.
Future<void> fillAndSave(WidgetTester pTester, String pText) async {
  await pTester.pumpAndSettle();
  await pTester.enterText(find.byType(TextField).first, pText);
  await pTester.tap(find.text('Enregistrer'));
  await pTester.pumpAndSettle();
}

void main() {
  late MemoryStorage vStorage;
  late WorksitesController vController;

  setUp(() {
    vStorage = MemoryStorage();
    vController = WorksitesController(vStorage);
  });

  testWidgets("l'application s'ouvre sur la liste des chantiers, vide", (pTester) async {
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    expect(find.text('Mes chantiers'), findsOneWidget);
    expect(find.textContaining('Aucun chantier'), findsOneWidget);
  });

  testWidgets('on crée un chantier, une pièce et ses quatre murs', (pTester) async {
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Nouveau chantier'));
    await fillAndSave(pTester, 'Maison');
    await pTester.tap(find.text('Nouvelle pièce'));
    await fillAndSave(pTester, 'Salon');
    for (final vLength in ['400', '300', '400', '300']) {
      // Le plan prend de la place : on fait défiler jusqu'au bouton.
      await pTester.scrollUntilVisible(
        find.text('Ajouter un mur'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await pTester.tap(find.text('Ajouter un mur'));
      await fillAndSave(pTester, vLength);
    }

    await pTester.scrollUntilVisible(
      find.text('Mur 4'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mur 4'), findsOneWidget);
    await pTester.scrollUntilVisible(
      find.textContaining('les mesures sont cohérentes'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('les mesures sont cohérentes'), findsOneWidget);
    expect(find.textContaining('12,00 m²'), findsWidgets);
    expect(vStorage.saved.single.rooms.single.walls, hasLength(4));
  });
}
