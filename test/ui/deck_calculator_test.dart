import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('terrasse : lames et lambourdes suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Terrasse bois');
    await pTester.tap(find.text('Terrasse bois'));
    await pTester.pumpAndSettle();

    expect(find.text('35 lames'), findsOneWidget);
    expect(find.text('9 lambourdes tous les 54 cm, soit 7 barres de 4 m'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Largeur (cm)'), '150');
    await pTester.pump();
    expect(find.text('18 lames'), findsOneWidget);
  });
}
