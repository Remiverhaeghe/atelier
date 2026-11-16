@Tags(['captures'])
library;

import 'dart:io';

import 'package:atelier/app.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  final vController = WorksitesController(MemoryStorage()..saved = [demoWorksite()]);
  await vController.load();
  await pTester.pumpWidget(AtelierApp(controller: vController));
  await pTester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester pTester, Finder pFinder) async {
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
      ('Parquet', '04-parquet'),
      ('Pose', '05-pose'),
      ('Plinthes', '06-plinthes'),
      ('Guide', '07-guide'),
    ]) {
      await tapAndSettle(pTester, find.widgetWithText(Tab, vTab));
      await capture(vName);
    }

    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    await tapAndSettle(pTester, find.byTooltip('Courses et budget'));
    await capture('08-courses');
  });

  testWidgets('plan de la pièce en thème sombre', (pTester) async {
    pTester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(pTester.platformDispatcher.clearPlatformBrightnessTestValue);
    await openApp(pTester);
    await tapAndSettle(pTester, find.text('Maison de démonstration'));
    await tapAndSettle(pTester, find.text('Chambre'));
    await capture('09-piece-sombre');
  });
}
