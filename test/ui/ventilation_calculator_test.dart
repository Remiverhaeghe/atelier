import 'package:atelier/ui/ventilation_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('VMC : débits et bouches suivent les pièces', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const VentilationCalculator()));

    expect(find.text('180 m³/h extraits au plus fort'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Salles d\'eau'), '2');
    await pTester.pump();
    expect(find.text('210 m³/h extraits au plus fort'), findsOneWidget);
    expect(find.text('2 salles d\'eau : 30 m³/h chacune'), findsOneWidget);
    expect(find.textContaining('4 bouches'), findsOneWidget);
  });
}
