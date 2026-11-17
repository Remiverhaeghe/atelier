import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('tablette murale : équerres, bras et chevilles suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Tablette murale sur équerres'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Tablette murale sur équerres'));
    await pTester.pumpAndSettle();

    // 120 × 25 cm en contreplaqué de 18 mm, livres, mur en béton
    expect(find.text('2 équerres, 90 cm entre axes'), findsOneWidget);
    expect(find.textContaining('20 cm au moins'), findsOneWidget);
    expect(find.textContaining('Environ 51 kg chargée'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Largeur (cm)'), '200');
    await pTester.pump();
    expect(find.text('3 équerres, 85 cm entre axes'), findsOneWidget);
  });
}
