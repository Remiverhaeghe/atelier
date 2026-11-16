import 'package:atelier/ui/diy_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('faire soi-même : économie par heure, puis les aides retournent le choix', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const DiyCalculator()));

    expect(find.text('1400,00 € économisés'), findsOneWidget);
    expect(find.text('28 h de travail à prévoir'), findsOneWidget);
    expect(find.text('Chaque heure passée vous rapporte 50,00 €'), findsOneWidget);

    await pTester.tap(find.text('Première fois'));
    await pTester.pump();
    expect(find.text('14 h de travail à prévoir'), findsOneWidget);

    await pTester.tap(find.text('Aides réservées à un artisan RGE'));
    await pTester.pump();
    await pTester.enterText(find.widgetWithText(TextField, 'Montant des aides (€)'), '1500');
    await pTester.pump();
    expect(find.text('Faire faire revient moins cher'), findsOneWidget);
    expect(find.textContaining('Chaque heure'), findsNothing);
  });
}
