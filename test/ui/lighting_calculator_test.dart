import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('éclairage : plus de lampes pour un atelier que pour un séjour', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text("Éclairage d'une pièce"));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text("Éclairage d'une pièce"));
    await pTester.pumpAndSettle();

    // 200 lx × 48 m² / (0,4 × 0,8) = 30 000 lm : 10 lampes, complétées en 4 × 3
    expect(find.text('12 lampes de 3000 lm'), findsOneWidget);

    await pTester.tap(find.text('5000 lm'));
    await pTester.pumpAndSettle();
    expect(find.text('6 lampes de 5000 lm'), findsOneWidget);
  });
}
