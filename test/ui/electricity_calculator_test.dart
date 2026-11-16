import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('électricité : pièces ajoutées, prises au moins, mise en garde', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Électricité'));
    await pTester.pumpAndSettle();

    expect(find.textContaining('NF C 15-100'), findsOneWidget);
    expect(find.text('Aucune prise'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ActionChip, 'Cuisine'));
    await pTester.tap(find.widgetWithText(ActionChip, 'Séjour'));
    await pTester.pump();
    expect(find.text('11 prises au moins'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Surface du séjour (m²)'), '30');
    await pTester.pump();
    expect(find.text('14 prises au moins'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer').first);
    await pTester.pump();
    expect(find.text('8 prises au moins'), findsOneWidget);
  });
}
