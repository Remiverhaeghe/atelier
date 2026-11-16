import 'package:atelier/ui/concrete_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('béton : dalle au sac, puis grande dalle en toupie et plots', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ConcreteCalculator()));
    expect(find.text('0,66 m³ de béton, 10 % de marge compris'), findsOneWidget);
    expect(find.textContaining('toupie'), findsNothing);

    await pTester.enterText(find.widgetWithText(TextField, '3000'), '6000');
    await pTester.pump();
    expect(find.textContaining('toupie'), findsOneWidget);

    await pTester.tap(find.text('Plots ou poteaux'));
    await pTester.pumpAndSettle();
    expect(find.text('0,3 m³ de béton, 10 % de marge compris'), findsOneWidget);
  });
}
