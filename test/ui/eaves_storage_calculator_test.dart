import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/eaves_storage_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('placard sous rampant : façade à 1,20 m sous un toit à 45°', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Placard sous rampant');
    await pTester.tap(find.text('Placard sous rampant'));
    await pTester.pumpAndSettle();

    expect(find.byType(EavesSketch), findsOneWidget);
    expect(find.text('Façade à 60 cm du mur de genou'), findsOneWidget);
    expect(find.text('1296 litres de rangement'), findsOneWidget);
    expect(find.text('4 modules de 60 cm, une porte chacun'), findsOneWidget);
    expect(
      find.text('5 montants, 60 cm côté mur et 120 cm côté façade, coupés à 45°'),
      findsOneWidget,
    );
    expect(find.text('4 portes de 60 × 110 cm, 3 charnières chacune'), findsOneWidget);
    expect(find.text('4 bacs sur roulettes de 56 × 55 cm, hauts de 40 cm'), findsOneWidget);
    expect(find.text('Une tablette à 45 cm, profonde de 60 cm'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur de la façade (cm)'), '50');
    await pTester.pump();
    expect(find.byType(EavesSketch), findsNothing);
    expect(find.textContaining('plus haute que le mur de genou'), findsOneWidget);
  });
}
