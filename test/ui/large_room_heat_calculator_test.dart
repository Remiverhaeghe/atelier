import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('grand volume : brasseurs sous 5 m, rien sous 2,50 m', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Chauffer un grand volume'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Chauffer un grand volume'));
    await pTester.pumpAndSettle();

    expect(find.text('7020 W'), findsOneWidget);
    expect(find.textContaining('2 brasseurs d'), findsOneWidget);
    expect(find.text('Ou un poêle de 8 kW nominal'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur moyenne sous plafond (cm)'),
      '250',
    );
    await pTester.pump();
    expect(find.textContaining('brasseur'), findsNothing);
    expect(find.text('Radiateurs classiques possibles à cette hauteur'), findsOneWidget);
  });
}
