import 'package:atelier/ui/exterior_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('façade puis clôture', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ExteriorCalculator()));

    // 8 m sur 5,50 m moins 6 m² d'ouvertures
    expect(find.text('38,00 m²'), findsOneWidget);
    expect(find.text('26 sacs de 25 kg d\'enduit monocouche'), findsOneWidget);

    await pTester.tap(find.text('Clôture'));
    await pTester.pumpAndSettle();
    expect(find.text('10 panneaux de 2,50 m'), findsOneWidget);
    expect(find.text('11 poteaux'), findsOneWidget);
    expect(find.textContaining('Dernier panneau'), findsNothing);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Longueur de la clôture (mm)'),
      '23400',
    );
    await pTester.pump();
    expect(find.text('Dernier panneau recoupé à 90 cm'), findsOneWidget);
  });
}
