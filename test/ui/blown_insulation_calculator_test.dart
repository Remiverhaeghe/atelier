import 'package:atelier/logic/blown_insulation.dart';
import 'package:atelier/ui/blown_insulation_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('laine soufflée : sacs puis ouate de cellulose', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const BlownInsulationCalculator()));
    expect(find.text('15 sacs'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<BlownMaterial>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Ouate de cellulose').last);
    await pTester.pumpAndSettle();
    expect(find.text('52 sacs'), findsOneWidget);
  });
}
