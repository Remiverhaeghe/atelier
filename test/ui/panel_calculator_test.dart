import 'package:atelier/ui/panel_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('débit : pièce ajoutée puis retirée, panneaux comptés', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const PanelCalculator()));

    expect(find.text('1 panneau'), findsOneWidget);
    expect(find.text('Panneau 1'), findsOneWidget);

    await pTester.tap(find.text('Ajouter une pièce'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Longueur invalide.'), findsOneWidget);
    await pTester.enterText(find.byType(TextField).at(0), '240');
    await pTester.enterText(find.byType(TextField).at(1), '120');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(find.text('2 panneaux'), findsOneWidget);
    expect(find.text('1 × 240 × 120 cm'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer').last);
    await pTester.pumpAndSettle();
    expect(find.text('1 panneau'), findsOneWidget);
  });
}
