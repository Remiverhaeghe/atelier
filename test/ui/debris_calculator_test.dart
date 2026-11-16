import 'package:atelier/ui/debris_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('gravats : big bags et voyages suivent ce qu\'on ajoute', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const DebrisCalculator()));

    // 10 m² de carrelage et chape sur 6 cm : 0,9 m³ en vrac, 1 200 kg
    expect(find.text('0,9 m³ en vrac'), findsOneWidget);
    expect(find.text('1200 kg à porter'), findsOneWidget);
    expect(find.text('2 big bags d\'un mètre cube'), findsOneWidget);
    expect(find.text('3 voyages de remorque'), findsOneWidget);

    await pTester.tap(find.text('Ajouter un déchet'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Plâtre et placo :'), findsOneWidget);
    expect(find.text('3 big bags d\'un mètre cube'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer').first);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Gravats (béton, carrelage, brique) :'), findsNothing);
    expect(find.text('1 big bag d\'un mètre cube'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Surface (m²)'), '40');
    await pTester.pump();
    expect(find.text('1 voyage de remorque'), findsOneWidget);
    expect(find.text('0,73 m³ en vrac'), findsOneWidget);
  });
}
