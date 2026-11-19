import 'package:atelier/logic/roof_window.dart';
import 'package:atelier/ui/attic_section_calculator.dart';
import 'package:atelier/ui/mezzanine_calculator.dart';
import 'package:atelier/ui/roof_lining_calculator.dart';
import 'package:atelier/ui/roof_window_calculator.dart';
import 'package:atelier/ui/stair_calculator.dart';
import 'package:atelier/ui/wood_window_calculator.dart';
import 'package:atelier/ui/work_sheet_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('pièce sous rampants : surface debout perdue en isolant par l\'intérieur', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const AtticSectionCalculator()));
    await pTester.pumpAndSettle();
    await scrollToFirst(pTester, find.text('Isoler les rampants par l\'intérieur'));
    expect(find.text('Isoler les rampants par l\'intérieur'), findsOneWidget);
    expect(find.text('2,6 m² de surface debout en moins (17 %)'), findsOneWidget);
    expect(find.textContaining('environ 5,7 m²·K/W'), findsOneWidget);

    await scrollToFirst(pTester, find.widgetWithText(TextField, 'Épaisseur contre les jambettes (cm)'));
    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur sous les rampants (cm)'), '0');
    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur contre les jambettes (cm)'), '0');
    await pTester.pump();
    expect(find.text('0 m² de surface debout en moins (0 %)'), findsOneWidget);
  });

  testWidgets('fiches de chantier : fenêtre bois, embrasure, mezzanine, escalier, rampants', (
    pTester,
  ) async {
    tallScreen(pTester);
    for (final vScreen in const <Widget>[
      WoodWindowCalculator(),
      RoofLiningCalculator(),
      MezzanineCalculator(),
      StairCalculator(riseMm: 2700),
      AtticSectionCalculator(),
    ]) {
      await pTester.pumpWidget(localized(vScreen));
      await pTester.pumpAndSettle();
      final vSheet = pTester.widget<PrintSheetButton>(find.byType(PrintSheetButton)).sheet();
      expect(vSheet.measures, isNotEmpty, reason: vScreen.runtimeType.toString());
      expect(vSheet.results, isNotEmpty, reason: vScreen.runtimeType.toString());
    }
  });

  testWidgets('fenêtre de toit : stores et volets à la taille de la référence', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RoofWindowCalculator()));
    expect(find.textContaining('commande la taille'), findsNothing);

    await pTester.enterText(find.widgetWithText(TextField, 'Référence de la fenêtre en place, sur sa plaque (ex. MK08 ou 308)'), 'MK08');
    await pTester.pump();
    expect(find.text('Stores et volets : commande la taille MK08'), findsOneWidget);
    expect(find.textContaining('Posé dedans'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Volet roulant'));
    await pTester.pump();
    expect(find.textContaining('Posé dehors'), findsOneWidget);
  });

  test('un store dehors arrête mieux la chaleur qu\'un store dedans', () {
    for (final vAccessory in RoofWindowAccessory.values) {
      expect(vAccessory.heatBlock, vAccessory.outside ? 3 : 1, reason: vAccessory.name);
    }
  });
}
