import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('plancher : la charge suit les solives mesurées', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Ce que porte un plancher');
    await pTester.tap(find.text('Ce que porte un plancher'));
    await pTester.pumpAndSettle();

    expect(find.text('Environ 260 kg/m² en plus du plancher lui-même'), findsOneWidget);
    expect(find.textContaining('poutre sous le milieu de la portée : 1538 kg/m²'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Portée des solives, entre appuis (cm)'),
      '200',
    );
    await pTester.pump();
    expect(find.text('Environ 1538 kg/m² en plus du plancher lui-même'), findsOneWidget);
  });
}
