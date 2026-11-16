import 'package:atelier/ui/conditions_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('conditions : ce qui est possible suit la température saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ConditionsCalculator()));

    expect(find.text('On peut y aller'), findsNWidgets(8));

    await pTester.enterText(find.byType(TextField).first, '-2');
    await pTester.pump();
    expect(find.text('On peut y aller'), findsNothing);
    expect(find.text('Trop froid : 8 °C au moins'), findsOneWidget);

    await pTester.enterText(find.byType(TextField).first, '20');
    await pTester.enterText(find.byType(TextField).at(2), '10');
    await pTester.pump();
    expect(find.textContaining('Risque de condensation'), findsNWidgets(3));
  });
}
