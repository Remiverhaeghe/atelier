import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/wood_window_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('fenêtre bois : vitrage à commander et alerte de bois trop mince', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Fenêtre bois sur mesure');
    await pTester.tap(find.text('Fenêtre bois sur mesure'));
    await pTester.pumpAndSettle();

    expect(find.text('Vitrage 70,2 × 90,2 cm'), findsOneWidget);
    expect(find.text('2 traverses de 75,2 cm, tenons compris'), findsOneWidget);
    expect(find.byType(WoodWindowSketch), findsOneWidget);
    expect(find.textContaining('Bois trop mince'), findsNothing);

    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur du bois (mm)'), '58');
    await pTester.pump();
    expect(find.textContaining('Bois trop mince'), findsOneWidget);
  });
}
