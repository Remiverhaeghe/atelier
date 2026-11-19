import 'package:atelier/logic/board_types.dart';
import 'package:atelier/ui/board_type_screen.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/glue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('panneau : un plancher en OSB, et le MDF de 19 mm se porte à deux', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Choisir un panneau');
    await pTester.tap(find.text('Choisir un panneau'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Plancher'));
    await pTester.pumpAndSettle();
    expect(find.text('OSB'), findsOneWidget);
    expect(find.text('MDF'), findsNothing);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Meuble à peindre'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('18 mm'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('19 mm').last);
    await pTester.pumpAndSettle();
    expect(find.text('Une plaque de 250 × 125 cm pèse 45 kg : à porter à deux'), findsOneWidget);
  });

  testWidgets('chaque panneau se dessine en relief', (pTester) async {
    tallScreen(pTester);
    for (final vBoard in BoardType.values) {
      await pTester.pumpWidget(
        localized(
          SizedBox(
            height: 200,
            child: BoardSketch(key: ValueKey(vBoard), board: vBoard),
          ),
        ),
      );
      expect(pTester.takeException(), isNull, reason: vBoard.name);
    }
  });

  testWidgets('colles : serre-joints selon la longueur, colle contact sans serrage', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GlueScreen()));
    // 80 cm de collage : un serre-joint à chaque bout et tous les 25 cm
    expect(find.text('Serrer 30 min au moins, avec 5 serre-joints sur ce collage'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Longueur du collage (cm)'), '20');
    await pTester.pump();
    expect(find.text('Serrer 30 min au moins, avec 2 serre-joints sur ce collage'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Stratifié sur panneau'));
    await pTester.pumpAndSettle();
    expect(find.text('Pas de serre-joints : on presse fort une fois, ou on cale'), findsOneWidget);
  });
}
