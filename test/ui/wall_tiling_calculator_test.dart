import 'package:atelier/ui/wall_tiling_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('crédence : rangées, prises et silicone suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const WallTilingCalculator()));

    expect(find.text('2 cartons'), findsOneWidget);
    expect(find.text('5 rangées entières depuis le bas, coupe de 9 cm en haut'), findsOneWidget);
    expect(find.textContaining('240 cm'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Prises et interrupteurs dans la faïence'),
      '3',
    );
    await pTester.pump();
    expect(find.textContaining('3 découpes'), findsOneWidget);

    await pTester.tap(find.text('2'));
    await pTester.pump();
    expect(find.text('Profilé de finition : 120 cm'), findsOneWidget);

    await pTester.tap(find.text('Posée sur un plan de travail'));
    await pTester.pump();
    expect(find.textContaining('silicone'), findsNothing);
  });
}
