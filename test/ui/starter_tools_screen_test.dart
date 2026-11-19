import 'package:atelier/logic/gestures.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/gestures_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('caisse à outils : cocher ce qu\'on a fait baisser ce qui manque', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Caisse à outils du débutant'));
    await pTester.pumpAndSettle();

    // 11 outils indispensables, de 145 à 381 € en tout
    expect(find.text('Il manque 11 outils indispensables : 145 à 381 €'), findsOneWidget);
    expect(find.textContaining('pour : Scier droit, Couper un onglet à 45°'), findsOneWidget);

    await pTester.tap(find.text('Perceuse-visseuse sans fil'));
    await pTester.pump();
    expect(find.text('Il manque 10 outils indispensables : 85 à 231 €'), findsOneWidget);
  });

  testWidgets('un geste dit de quels outils il a besoin', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GestureScreen(gesture: Gesture.mitre)));
    await pTester.pumpAndSettle();
    expect(find.text('Boîte à onglets'), findsOneWidget);
    expect(find.text('Scie égoïne'), findsOneWidget);
  });
}
