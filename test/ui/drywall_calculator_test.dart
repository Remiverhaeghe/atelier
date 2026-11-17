import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('placo : plaques et résistance suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Placo et isolation'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Placo et isolation'));
    await pTester.pumpAndSettle();

    expect(find.text('4 plaques'), findsOneWidget);
    expect(find.textContaining('R = 2,86'), findsOneWidget);

    await pTester.tap(find.text('Cloison (plaques des deux côtés)'));
    await pTester.pump();
    expect(find.text('8 plaques'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Épaisseur de laine (cm), 0 sans isolation'),
      '14',
    );
    await pTester.pump();
    expect(find.textContaining('R = 4'), findsOneWidget);
  });
}
