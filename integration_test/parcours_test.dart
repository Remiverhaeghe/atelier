import 'dart:io';

import 'package:atelier/app.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/backups.dart';
import 'package:atelier/storage/worksite_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Remplit la boîte de dialogue ouverte et l'enregistre.
Future<void> fillAndSave(WidgetTester pTester, String pText) async {
  await pTester.pumpAndSettle();
  await pTester.enterText(
    find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)).first,
    pText,
  );
  await pTester.tap(find.text('Enregistrer'));
  await pTester.pumpAndSettle();
}

/// Parcours sur un vrai téléphone (émulateur en CI) : saisie, fichier écrit, relecture.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File vFile;

  setUp(() async {
    final vFolder = await getTemporaryDirectory();
    vFile = File('${vFolder.path}/parcours/chantiers.json');
    if (vFile.existsSync()) {
      vFile.deleteSync();
    }
  });

  testWidgets('un chantier saisi est relu au redémarrage', (pTester) async {
    final vController = WorksitesController(WorksiteStore(vFile));
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Nouveau chantier'));
    await fillAndSave(pTester, 'Maison démo');
    await pTester.tap(find.text('Nouvelle pièce'));
    await fillAndSave(pTester, 'Salon');
    expect(find.text('Salon'), findsWidgets);

    // Écriture sur le stockage réel du téléphone, puis relecture comme au lancement.
    await pTester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    expect(vFile.existsSync(), isTrue);
    final vReloaded = WorksitesController(WorksiteStore(vFile));
    await pTester.runAsync(vReloaded.load);
    expect(vReloaded.worksites.single.name, 'Maison démo');
    expect(vReloaded.worksites.single.rooms.single.name, 'Salon');
  });

  testWidgets('un chantier relu du téléphone donne sa surface habitable', (pTester) async {
    // Fichier écrit comme par une session précédente, puis relu au lancement
    final vStore = WorksiteStore(vFile);
    await pTester.runAsync(
      () => vStore.save(const [
        Worksite(
          id: 'w',
          name: 'Maison démo',
          rooms: [
            Room(
              id: 'salon',
              name: 'Salon',
              walls: [
                Wall(lengthMm: 4000),
                Wall(lengthMm: 3000),
                Wall(lengthMm: 4000),
                Wall(lengthMm: 3000),
              ],
            ),
          ],
        ),
      ]),
    );
    final vController = WorksitesController(WorksiteStore(vFile));
    await pTester.runAsync(vController.load);
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Maison démo'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byTooltip('Surface habitable'));
    await pTester.pumpAndSettle();
    expect(find.text('12,00 m²'), findsOneWidget);
  });

  testWidgets('chaque enregistrement laisse la sauvegarde du jour sur le téléphone', (
    pTester,
  ) async {
    final vFolder = Directory('${vFile.parent.path}/sauvegardes');
    if (vFolder.existsSync()) {
      vFolder.deleteSync(recursive: true);
    }
    final vBackups = Backups(vFolder);
    final vController = WorksitesController(WorksiteStore(vFile, backups: vBackups));
    await pTester.runAsync(vController.load);
    await pTester.pumpWidget(AtelierApp(controller: vController));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Nouveau chantier'));
    await fillAndSave(pTester, 'Atelier du fond');
    await pTester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));

    final vList = vBackups.list();
    expect(vList, hasLength(1));
    expect(vList.single.file.readAsStringSync(), contains('Atelier du fond'));
  });
}
