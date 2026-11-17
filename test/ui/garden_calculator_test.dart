import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('jardin : les quantités suivent les surfaces', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Jardin'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Jardin'));
    await pTester.pumpAndSettle();
    expect(find.text('Pas de semences'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Surface de pelouse (m²)'), '60');
    await pTester.pump();
    expect(find.text('3 boîtes de semences de 1 kg'), findsOneWidget);

    await pTester.tap(find.text('Gazon en rouleaux plutôt que semé'));
    await pTester.pump();
    expect(find.text('63 rouleaux de gazon'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Surface de massifs (m²)'), '10');
    await pTester.pump();
    expect(find.text('50 sacs de terre végétale'), findsOneWidget);
  });
}
