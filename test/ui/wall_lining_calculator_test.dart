import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/wall_lining_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('isolation par l’intérieur d’un pan de mur saisi à la main', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, "Isolation des murs par l'intérieur");
    await pTester.tap(find.text("Isolation des murs par l'intérieur"));
    await pTester.pumpAndSettle();

    expect(find.byType(LiningSketch), findsOneWidget);
    expect(find.text('Isolant 14 cm, 17,1 cm pris sur la pièce'), findsOneWidget);
    expect(find.text("10,00 m² de mur à doubler, 3 paquets d'isolant"), findsOneWidget);
    expect(find.text('0,68 m² perdus le long de ce mur'), findsOneWidget);
    expect(find.text('8 montants à 60 cm, 8 m de rails haut et bas'), findsOneWidget);

    await pTester.tap(find.text('Fourrures métalliques sur appuis'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Complexe isolant collé').last);
    await pTester.pumpAndSettle();
    expect(find.text('2 sacs de mortier adhésif de 25 kg'), findsOneWidget);
    expect(find.textContaining('montants à 60 cm'), findsNothing);
  });

  testWidgets('murs cochés pièce par pièce : surface perdue de chacune', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(WallLiningCalculator(rooms: [rectangleRoom()])));
    expect(find.text('Coche les murs qui donnent dehors'), findsWidgets);

    await pTester.tap(find.widgetWithText(FilterChip, 'Mur 1'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.widgetWithText(FilterChip, 'Mur 2'));
    await pTester.pumpAndSettle();
    expect(find.text('Salon : 1,17 m² perdus sur 12,00 m²'), findsOneWidget);

    await pTester.tap(find.widgetWithText(FilterChip, 'Mur 2'));
    await pTester.pumpAndSettle();
    expect(find.text('Salon : 0,68 m² perdus sur 12,00 m²'), findsOneWidget);
  });
}
