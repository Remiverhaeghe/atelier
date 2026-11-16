import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('étagère : la liste de débit suit la saisie, la portée est surveillée', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Étagère sur mesure'));
    await pTester.pumpAndSettle();

    expect(find.text('5 × tablette de 76,4 × 30 cm'), findsOneWidget);
    expect(find.textContaining('Tablette trop large'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Largeur (cm)'), '60');
    await pTester.pump();
    expect(find.text('5 × tablette de 56,4 × 30 cm'), findsOneWidget);
    expect(find.textContaining('Tablette trop large'), findsNothing);
  });
}
