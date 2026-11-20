@Tags(['captures'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'captures_test.dart' show capture, capturesDone, loadFonts, openApp, tapAndSettle;

/// Captures des projets modèles, du mode atelier et des outils de chantier (lots 187 à 210).
void main() {
  setUpAll(loadFonts);

  Future<void> vBack(WidgetTester pTester) async {
    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
  }

  testWidgets('projets prêts à suivre et mode atelier', (pTester) async {
    await openApp(pTester);
    await tapAndSettle(pTester, find.byTooltip('Calculs'));
    await tapAndSettle(pTester, find.text('Projets prêts à suivre'));
    await capture('40-projets');
    await tapAndSettle(pTester, find.text('Châssis fixe à la place d\'un plexi'));
    await capture('41-projet-chassis');
    await vBack(pTester);
    await tapAndSettle(pTester, find.text('Étagère murale'));
    await tapAndSettle(pTester, find.text('Suivre en mode atelier'));
    await capture('42-mode-atelier');
    await vBack(pTester);
    await vBack(pTester);
    await vBack(pTester);
    await tapAndSettle(pTester, find.text('Mesure par photo'));
    await capture('43-mesure-photo-a4');
    await vBack(pTester);
    await tapAndSettle(pTester, find.text('Le bon outil'));
    await capture('44-bon-outil');
    await vBack(pTester);
    await tapAndSettle(pTester, find.text('Comparer des devis'));
    await capture('45-comparer-devis');
    await vBack(pTester);
    await tapAndSettle(pTester, find.text('Gravats et déchetterie'));
    await capture('46-dechets');
    capturesDone();
  });
}
