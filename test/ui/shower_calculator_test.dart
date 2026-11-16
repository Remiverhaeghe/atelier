import 'package:atelier/ui/shower_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('douche : niveaux et étanchéité suivent la bonde et les murs', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ShowerCalculator()));

    expect(find.text('Sol fini au bord : 117 mm au-dessus de la dalle'), findsOneWidget);
    expect(find.text('7 m de bande d\'angle'), findsOneWidget);

    await pTester.tap(find.text('Caniveau au mur'));
    await pTester.pumpAndSettle();
    expect(find.text('Sol fini au bord : 123 mm au-dessus de la dalle'), findsOneWidget);

    await pTester.tap(find.text('1'));
    await pTester.pumpAndSettle();
    expect(find.text('1,2 m de bande d\'angle'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur du siphon (mm, voir la notice)'),
      '60',
    );
    await pTester.pump();
    expect(find.text('Sol fini au bord : 103 mm au-dessus de la dalle'), findsOneWidget);
  });
}
