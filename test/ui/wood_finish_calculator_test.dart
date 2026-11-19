import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/wood_finish_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('finitions : vernis d\'un meuble, vitrificateur du sol, lasure dehors', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Finitions du bois');
    await pTester.tap(find.text('Finitions du bois'));
    await pTester.pumpAndSettle();

    // 4 m² en trois couches de vernis à 12 m²/L
    expect(find.text('1 L pour 3 couches'), findsOneWidget);
    expect(find.text('1 × 1 L'), findsOneWidget);
    expect(find.text('12 h entre deux couches, 24 h d\'attente en tout'), findsOneWidget);
    expect(find.text('film en surface'), findsOneWidget);
    expect(find.byType(FinishSketch), findsOneWidget);

    await pTester.tap(find.text('Sol'));
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Cire'), findsNothing);
    expect(find.text('1,2 L pour 3 couches'), findsOneWidget);
    expect(find.text('1 × 0,5 L'), findsOneWidget);

    await pTester.tap(find.text('Dehors'));
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Lasure'), findsOneWidget);
    expect(find.text('entre dans le bois'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Surface à traiter (m²)'), '10');
    await pTester.pump();
    expect(find.text('2,5 L pour 3 couches'), findsOneWidget);
    expect(find.text('1 × 2,5 L'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Huile'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('sans poncer'), findsOneWidget);
  });
}
