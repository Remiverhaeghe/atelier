import 'package:atelier/logic/screed.dart';
import 'package:atelier/ui/screed_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('ragréage puis enduit : sacs, attente et couches', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ScreedCalculator()));

    expect(find.text('5 sacs de 25 kg'), findsOneWidget);
    expect(find.text('Attendre 2 jours avant la suite'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<Covering>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Parquet collé').last);
    await pTester.pumpAndSettle();
    expect(find.text('Attendre 4 jours avant la suite'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<Coating>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enduit de lissage de mur').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('couches de 2 mm'), findsOneWidget);
    expect(find.textContaining('primaire'), findsNothing);
  });
}
