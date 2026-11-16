import 'package:atelier/ui/gutter_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('gouttière : une descente de 80, deux pour une longue façade', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GutterCalculator()));
    expect(find.text('1 descente de 80 mm'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, '10000'), '16000');
    await pTester.pump();
    expect(find.text('2 descentes de 80 mm'), findsOneWidget);
  });
}
