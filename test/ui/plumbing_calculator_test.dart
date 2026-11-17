import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('plomberie : appareils ajoutés, longueur réglée, pente affichée', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Plomberie'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Plomberie'));
    await pTester.pumpAndSettle();
    expect(find.text('Ajoute les appareils à raccorder.'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ActionChip, 'Douche'));
    await pTester.pump();
    expect(find.text('3 m de PVC de 40 mm'), findsOneWidget);
    expect(find.text('PVC de 40 mm sur 2 m : 2 à 6 cm de dénivelé'), findsOneWidget);

    await pTester.tap(find.byTooltip('Allonger de 50 cm'));
    await pTester.pump();
    expect(find.text('PVC de 40 mm sur 2,5 m : 2,5 à 7,5 cm de dénivelé'), findsOneWidget);
  });
}
