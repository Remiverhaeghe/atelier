import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('fenêtre de toit : chevêtre entre chevrons serrés, pas entre chevrons larges', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Fenêtre de toit');
    await pTester.tap(find.text('Fenêtre de toit'));
    await pTester.pumpAndSettle();

    expect(find.text('Fenêtre de 55 × 118 cm'), findsOneWidget);
    expect(find.textContaining('Un chevron à couper'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Entraxe des chevrons (cm)'), '90');
    await pTester.pump();
    expect(find.textContaining('Un chevron à couper'), findsNothing);
    expect(find.textContaining("jusqu'à 66 cm de large"), findsOneWidget);
  });

  testWidgets('fenêtre de toit : la référence de la plaque donne la taille', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Fenêtre de toit');
    await pTester.tap(find.text('Fenêtre de toit'));
    await pTester.pumpAndSettle();

    final vReference = find.widgetWithText(
      TextField,
      'Référence de la fenêtre en place, sur sa plaque (ex. MK08 ou 308)',
    );
    await pTester.enterText(vReference, 'GGL 308');
    await pTester.pump();
    expect(find.textContaining('Cadre de 78 × 140 cm'), findsOneWidget);
    expect(find.textContaining('Fenêtre de 78 ×'), findsOneWidget);

    await pTester.enterText(vReference, 'ZZ');
    await pTester.pump();
    expect(find.textContaining('Référence non reconnue'), findsOneWidget);
  });
}

