import 'package:atelier/logic/insulation.dart';
import 'package:atelier/ui/insulation_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('isolation : épaisseur et quantités suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const InsulationCalculator()));

    // Rampants en laine de verre, R 6 : 210 mm, en une couche de 240
    expect(find.text('24 cm'), findsOneWidget);
    expect(find.textContaining('28 suspentes'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<Insulant>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Ouate de cellulose soufflée').last);
    await pTester.pumpAndSettle();
    expect(find.text('24 cm'), findsOneWidget);
    expect(find.textContaining('sacs d\'ouate'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<InsulatedPart>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Plancher bas').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Pare-vapeur'), findsNothing);
  });
}
