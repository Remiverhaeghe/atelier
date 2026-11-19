@Tags(['captures'])
library;

import 'dart:io';

import 'package:atelier/app.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_storage.dart';
import 'demo.dart';

/// Polices de Flutter : sans elles, les tests dessinent des carrés à la place du texte.
Future<void> loadFonts() async {
  final vRoot = Platform.environment['FLUTTER_ROOT'];
  if (vRoot == null) {
    fail('FLUTTER_ROOT doit pointer vers le SDK Flutter pour charger les polices');
  }
  final vFolder = Directory('$vRoot/bin/cache/artifacts/material_fonts');
  ByteData vRead(File pFile) => ByteData.sublistView(pFile.readAsBytesSync());
  final vFiles = vFolder.listSync().whereType<File>().toList();
  bool vNamed(File pFile, String pStart) =>
      pFile.uri.pathSegments.last.toLowerCase().startsWith(pStart);

  final vRoboto = FontLoader('Roboto');
  for (final vFile in vFiles.where((pFile) => vNamed(pFile, 'roboto-'))) {
    vRoboto.addFont(Future.value(vRead(vFile)));
  }
  await vRoboto.load();

  // Polices de l'application, embarquées dans assets/fonts
  final vAssets = Directory('assets/fonts').listSync().whereType<File>().toList();
  for (final vFamily in ['BarlowSemiCondensed', 'Barlow', 'Caveat']) {
    final vLoader = FontLoader(vFamily);
    for (final vFile in vAssets.where((pFile) => vNamed(pFile, '${vFamily.toLowerCase()}-'))) {
      vLoader.addFont(Future.value(vRead(vFile)));
    }
    await vLoader.load();
  }
  final vIcons = FontLoader('MaterialIcons')
    ..addFont(Future.value(vRead(vFiles.firstWhere((pFile) => vNamed(pFile, 'materialicons')))));
  await vIcons.load();
}

/// Écran d'un téléphone courant : 1080 × 2340 pixels.
void phoneScreen(WidgetTester pTester) {
  pTester.view.physicalSize = const Size(1080, 2340);
  pTester.view.devicePixelRatio = 3;
  addTearDown(pTester.view.reset);
}

Future<void> capture(String pName) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('png/$pName.png'));

Future<void> openApp(WidgetTester pTester) async {
  phoneScreen(pTester);
  // Les tests remplacent les ombres par un trait noir ; les captures veulent les vraies.
  // Remis en fin de test par capturesDone, avant le contrôle des variables de dessin.
  debugDisableShadows = false;
  final vController = WorksitesController(MemoryStorage()..saved = [demoWorksite()]);
  await vController.load();
  await pTester.pumpWidget(AtelierApp(controller: vController));
  await pTester.pumpAndSettle();
}

void capturesDone() => debugDisableShadows = true;

/// Première liste verticale de l'écran : les champs de saisie ont aussi leur défilement.
Finder _vertical() => find
    .byWidgetPredicate(
      (pWidget) => pWidget is Scrollable && pWidget.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> tapAndSettle(WidgetTester pTester, Finder pFinder) async {
  // Une liste ne construit que ce qui est à l'écran : sous les tuiles d'accueil, les pièces
  // n'existent pas encore tant qu'on n'a pas fait défiler
  if (pFinder.evaluate().isEmpty) {
    // L'élément peut être au-dessus de l'écran : on repart du haut, puis on descend
    // Première liste verticale : la grille des calculs a aussi une rangée de puces horizontale
    final vScrollable = find
        .byWidgetPredicate(
          (pWidget) => pWidget is Scrollable && pWidget.axisDirection == AxisDirection.down,
        )
        .first;
    pTester.state<ScrollableState>(vScrollable).position.jumpTo(0);
    await pTester.pumpAndSettle();
    if (pFinder.evaluate().isEmpty) {
      await pTester.scrollUntilVisible(pFinder, 300, scrollable: vScrollable);
    }
  }
  await pTester.ensureVisible(pFinder);
  await pTester.pumpAndSettle();
  await pTester.tap(pFinder);
  await pTester.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  testWidgets('parcours du chantier de démonstration', (pTester) async {
    await openApp(pTester);
    await capture('01-chantiers');

    await tapAndSettle(pTester, find.text('Maison de démonstration'));
    await capture('02-chantier');

    await tapAndSettle(pTester, find.text('Salon'));
    await capture('03-piece');

    for (final (vTab, vName) in [
      ('Reprises', '10-reprises'),
      ('Parquet', '04-parquet'),
      ('Pose', '05-pose'),
      ('Plinthes', '06-plinthes'),
      ('Peinture', '11-peinture'),
      ('Guide', '07-guide'),
    ]) {
      await tapAndSettle(pTester, find.widgetWithText(Tab, vTab));
      await capture(vName);
    }

    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.byTooltip('Courses et budget'));
    await capture('08-courses');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.byTooltip('Conseils et tutos'));
    await tapAndSettle(pTester, find.text('Finir les plinthes au joint'));
    await capture('12-conseil');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.byTooltip('Calculs'));
    await capture('13-calculs');
    await tapAndSettle(pTester, find.text('Étagère sur mesure'));
    await capture('14-etagere');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Pièce sous rampants'));
    await capture('15-rampants');
    await tapAndSettle(pTester, find.text('En relief'));
    await capture('25-rampants-relief');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Embrasure de fenêtre de toit'));
    await capture('17-embrasure');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Fenêtre bois sur mesure'));
    await capture('16-fenetre-bois');
    await tapAndSettle(pTester, find.widgetWithText(ActionChip, 'Tenon'));
    await capture('18-lexique-tenon');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.widgetWithText(ActionChip, 'Feuillure'));
    await capture('19-lexique-feuillure');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Finitions du bois'));
    await capture('20-finitions');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Humidité et condensation'));
    await capture('21-condensation');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Faux plafond'));
    await capture('22-faux-plafond');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Placard sous rampant'));
    await capture('23-placard-rampant');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Gestes de base'));
    await tapAndSettle(pTester, find.text('Scier droit'));
    await capture('24-geste-scier');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Caisse à outils du débutant'));
    await capture('26-caisse-outils');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Diagnostic thermique'));
    await capture('27-diagnostic-thermique');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text("Isolation des murs par l'intérieur"));
    await capture('28-isolation-murs');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Par où commencer'));
    await tapAndSettle(pTester, find.text('Carrelage'));
    await capture('40-par-ou-commencer');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Contrôles qualité'));
    await capture('41-controles-qualite');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Sécurité par outil'));
    await tapAndSettle(pTester, find.text('Scie circulaire'));
    await capture('42-securite-scie');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Je me suis trompé'));
    await tapAndSettle(pTester, find.text('Coulure de vernis'));
    await capture('43-je-me-suis-trompe');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Bruit et voisinage'));
    await capture('44-bruit-voisinage');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Mode apprentissage'));
    await capture('45-mode-apprentissage');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Douche de plain-pied'));
    await pTester.scrollUntilVisible(
      find.text('Volumes de sécurité'),
      300,
      scrollable: _vertical(),
    );
    await pTester.pumpAndSettle();
    await capture('29-salle-eau');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Cuisine'));
    await pTester.scrollUntilVisible(
      find.text("Triangle d'activité"),
      300,
      scrollable: _vertical(),
    );
    await pTester.pumpAndSettle();
    await capture('30-cuisine');
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.text('Maison de démonstration'));
    await tapAndSettle(pTester, find.byTooltip('Électricité du plan'));
    await tapAndSettle(pTester, find.text('Salon'));
    await capture('31-prises-eclairage');
    capturesDone();
  });

  testWidgets('plan de la pièce en thème sombre', (pTester) async {
    pTester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(pTester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openApp(pTester);
    await tapAndSettle(pTester, find.text('Maison de démonstration'));
    await tapAndSettle(pTester, find.text('Chambre'));
    await capture('09-piece-sombre');
    capturesDone();
  });
}
