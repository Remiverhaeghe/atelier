import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('condensation : double vitrage à la limite, simple vitrage qui perle', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Humidité et condensation');
    await pTester.tap(find.text('Humidité et condensation'));
    await pTester.pumpAndSettle();

    // 20 °C et 60 % dedans, 0 °C dehors
    expect(find.text('L\'eau de l\'air se dépose sous 12 °C'), findsOneWidget);
    expect(find.text('La paroi est à 12,7 °C côté pièce'), findsOneWidget);
    expect(find.text('À la limite : une nuit plus froide et elle perle'), findsOneWidget);
    expect(find.text('Garde la pièce sous 62 % d\'humidité pour cette paroi'), findsOneWidget);

    await pTester.tap(find.text('Double vitrage'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Simple vitrage').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Elle est plus froide'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Température dehors (°C)'), '-10');
    await pTester.pump();
    expect(find.text('La paroi est à -2,6 °C côté pièce'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Humidité de la pièce (%)'), '120');
    await pTester.pump();
    expect(find.text('L\'eau de l\'air se dépose sous 12 °C'), findsOneWidget);
  });
}
