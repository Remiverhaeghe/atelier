import 'package:atelier/ui/stair_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('escalier : coupe, trémie et échappée contrôlée', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const StairCalculator()));

    expect(find.text('16 hauteurs de 17,5 cm'), findsOneWidget);
    expect(find.text('2 limons de 524,8 cm à débiter'), findsOneWidget);
    expect(find.textContaining('Trémie d\'au moins 308 cm'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Longueur de la trémie existante (cm), si vous l\'avez'),
      '250',
    );
    await pTester.pump();
    expect(find.textContaining('on se cogne la tête'), findsOneWidget);
  });
}
