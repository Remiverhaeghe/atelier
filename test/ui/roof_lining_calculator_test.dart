import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/roof_lining_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('embrasure : ouverture au plafond et mot expliqué', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Embrasure de fenêtre de toit');
    await pTester.tap(find.text('Embrasure de fenêtre de toit'));
    await pTester.pumpAndSettle();

    // 98 cm de fenêtre, 22 cm d'épaisseur à 40° : 22 × (1/tan 40° + tan 40°) de plus
    expect(find.text('Ouverture de 142,7 cm dans le rampant'), findsOneWidget);
    expect(find.byType(RoofLiningSketch), findsOneWidget);

    await pTester.ensureVisible(find.widgetWithText(ActionChip, 'Embrasure'));
    await pTester.tap(find.widgetWithText(ActionChip, 'Embrasure'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Le « tunnel » entre la fenêtre et la pièce'), findsOneWidget);
  });

  testWidgets('le lexique liste tous les mots du métier', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.byTooltip('Lexique'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Jambette'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Le petit mur bas'), findsOneWidget);
  });
}
