import 'package:atelier/ui/kitchen_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('cuisine : meubles, plans et hauteurs suivent les cotes', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const KitchenCalculator()));

    expect(find.textContaining('fileur de 3'), findsOneWidget);
    expect(find.text('Plans de travail : 300 cm'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Retour en L, 0 sans retour (mm)'),
      '1800',
    );
    await pTester.pump();
    expect(find.textContaining('Linéaire 2 :'), findsOneWidget);
    expect(find.text('Plans de travail : 300 + 246 cm'), findsOneWidget);

    await pTester.tap(find.text('Plaque au gaz'));
    await pTester.pump();
    expect(find.textContaining('Bas de la hotte à'), findsOneWidget);
  });
}
