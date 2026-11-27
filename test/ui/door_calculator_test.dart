import 'package:atelier/logic/units.dart';
import 'package:atelier/ui/door_calculator.dart';
import 'package:atelier/ui/plan_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('porte : bloc-porte, sens et cloison épaisse', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const DoorCalculator()));

    expect(find.text('Bloc-porte 83 cm × 204 cm'), findsOneWidget);
    expect(find.text('Poussant droit'), findsOneWidget);

    await pTester.tap(find.text('Paumelles à gauche'));
    await pTester.pump();
    expect(find.text('Poussant gauche'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur de la cloison (cm)'), '16');
    await pTester.pump();
    expect(find.textContaining('huisserie à recouvrement'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Largeur de l\'ouverture brute, porte déposée (cm)'),
      '60',
    );
    await pTester.pump();
    expect(find.textContaining('trop étroite'), findsOneWidget);
  });

  testWidgets('porte : le bloc-porte s\'écrit dans l\'unité choisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      PlanUnit(unit: FieldUnit.mm, child: localized(const DoorCalculator())),
    );

    expect(find.text('Bloc-porte 830 mm × 2040 mm'), findsOneWidget);
  });
}
