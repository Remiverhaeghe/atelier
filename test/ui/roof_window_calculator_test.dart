import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('fenêtre de toit : chevêtre entre chevrons serrés, pas entre chevrons larges', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Fenêtre de toit'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Fenêtre de toit'));
    await pTester.pumpAndSettle();

    expect(find.text('Fenêtre de 55 × 118 cm'), findsOneWidget);
    expect(find.textContaining('Un chevron à couper'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Entraxe des chevrons (cm)'), '90');
    await pTester.pump();
    expect(find.textContaining('Un chevron à couper'), findsNothing);
    expect(find.textContaining("jusqu'à 66 cm de large"), findsOneWidget);
  });
}
