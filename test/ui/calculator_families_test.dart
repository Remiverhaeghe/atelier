import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('la grille ne montre que la famille choisie, puis tout à nouveau', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    expect(find.widgetWithText(ChoiceChip, 'Tout'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Combles et toit'));
    await pTester.pumpAndSettle();
    expect(find.text('Pièce sous rampants'), findsOneWidget);
    expect(find.text('Placard sous rampant'), findsOneWidget);
    expect(find.text('Gestes de base'), findsNothing);
    expect(find.text('Terrasse bois'), findsNothing);

    await pTester.ensureVisible(find.widgetWithText(ChoiceChip, 'Dehors'));
    await pTester.tap(find.widgetWithText(ChoiceChip, 'Dehors'));
    await pTester.pumpAndSettle();
    expect(find.text('Terrasse bois'), findsOneWidget);
    expect(find.text('Pièce sous rampants'), findsNothing);

    await pTester.ensureVisible(find.widgetWithText(ChoiceChip, 'Tout'));
    await pTester.tap(find.widgetWithText(ChoiceChip, 'Tout'));
    await pTester.pumpAndSettle();
    expect(find.text('Gestes de base'), findsOneWidget);
  });

  test('chaque calcul a une famille, et chaque famille au moins un calcul', () {
    final vEntries = CalculatorsScreen.entries(AppLocalizationsFr());
    for (final vFamily in CalcFamily.values) {
      expect(vEntries.where((pEntry) => pEntry.family == vFamily), isNotEmpty, reason: vFamily.name);
    }
  });
}
