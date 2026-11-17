import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('mezzanine : solives, poutre et poteaux suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Mezzanine'));
    await pTester.pumpAndSettle();

    // 3 × 2 m contre un mur, chambre
    expect(find.text('9 solives de 45 × 145 mm en C24, tous les 40 cm'), findsOneWidget);
    expect(find.textContaining('1 poutre en lamellé-collé de 90 × 225 mm'), findsOneWidget);
    expect(find.textContaining('2 poteaux de 100 × 100 mm'), findsOneWidget);
    expect(find.textContaining('18 sabots'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Profondeur, portée des solives (cm)'),
      '350',
    );
    await pTester.pump();
    expect(find.text('9 solives de 45 × 170 mm en C24, tous les 40 cm'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Profondeur, portée des solives (cm)'),
      '800',
    );
    await pTester.pump();
    expect(find.textContaining('Portée trop grande'), findsOneWidget);
  });
}
