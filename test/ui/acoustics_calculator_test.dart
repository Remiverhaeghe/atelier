import 'package:atelier/ui/acoustics_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('phonique : cloison puis plancher de mezzanine', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const AcousticsCalculator()));

    expect(find.text('8 plaques de plâtre phoniques'), findsOneWidget);
    expect(find.textContaining('suspentes'), findsNothing);

    await pTester.tap(find.text('Plancher de mezzanine'));
    await pTester.pumpAndSettle();
    expect(find.text('4 plaques de plâtre phoniques'), findsOneWidget);
    expect(find.text('14 suspentes antivibratiles'), findsOneWidget);
    expect(find.textContaining('Le bruit de pas'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Surface (m²)'), '2');
    await pTester.pump();
    expect(find.text('1 plaque de plâtre phonique'), findsOneWidget);
  });
}
