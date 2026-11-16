import 'package:atelier/logic/roofing.dart';
import 'package:atelier/ui/roofing_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('couverture : les quantités suivent le pan et la tuile', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RoofingCalculator()));

    expect(find.text('394 × Tuiles à emboîtement'), findsOneWidget);
    expect(find.text('11 chevrons de 480 cm'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Débord de toit (cm)'), '0');
    await pTester.tap(find.byType(DropdownButtonFormField<RoofCovering>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Ardoises').last);
    await pTester.pumpAndSettle();
    expect(find.text('851 × Ardoises'), findsOneWidget);
  });
}
