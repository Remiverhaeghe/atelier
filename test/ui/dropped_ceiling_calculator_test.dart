import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/dropped_ceiling_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('faux plafond : de 3,50 m à 2,50 m, puis trop bas, puis presque rien', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Faux plafond');
    await pTester.tap(find.text('Faux plafond'));
    await pTester.pumpAndSettle();

    expect(find.byType(CeilingSketch), findsOneWidget);
    expect(find.textContaining('96 cm de vide'), findsOneWidget);
    expect(find.text('Suspentes à pivot sur tiges filetées, réglées au laser'), findsOneWidget);
    expect(find.text('12 fourrures de 3 m, sur 6 rangs tous les 60 cm'), findsOneWidget);
    expect(find.text('30 suspentes, une tous les 1,20 m au plus'), findsOneWidget);
    expect(find.text('30 tiges filetées d\'un mètre'), findsOneWidget);
    expect(find.text('8 plaques de plâtre de 1,20 × 2,50 m'), findsOneWidget);
    // 5 × 4 × 3,5 = 70 m³, dont 20 en moins
    expect(find.text('20 m³ en moins à chauffer, 29 % du volume de la pièce'), findsOneWidget);
    expect(find.textContaining('pièce à vivre'), findsNothing);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur voulue (cm)'), '210');
    await pTester.pump();
    expect(find.text('Sous 220 cm, la pièce n\'est plus une pièce à vivre'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur sous plafond aujourd\'hui (cm)'),
      '260',
    );
    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur voulue (cm)'), '250');
    await pTester.pump();
    expect(find.text('Suspentes réglables vissées au plafond, sans tige'), findsOneWidget);
    expect(find.textContaining('tiges filetées d\'un mètre'), findsNothing);
  });
}
