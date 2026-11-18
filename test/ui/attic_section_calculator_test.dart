import 'package:atelier/ui/attic_section_calculator.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('pièce sous rampants : surface debout, croquis et calcul expliqué', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Pièce sous rampants');
    await pTester.tap(find.text('Pièce sous rampants'));
    await pTester.pumpAndSettle();

    // 6 m entre jambettes de 80 cm, rampants à 40°, pièce de 4,20 m
    expect(find.text('15,2 m² habitables'), findsOneWidget);
    expect(find.text('25,2 m² au sol en tout'), findsOneWidget);
    expect(find.text('331,7 cm au point le plus haut'), findsOneWidget);
    expect(find.byType(AtticSketch), findsOneWidget);

    await pTester.tap(find.text('Comment c\'est calculé'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('119,2 cm de sol restent sous 1,80 m'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Plafond plat sous le faîtage, s\'il y en a un (cm)'),
      '250',
    );
    await pTester.pump();
    expect(find.text('250 cm au point le plus haut'), findsOneWidget);
  });
}
