import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/gestures.dart';
import 'package:atelier/ui/dropped_ceiling_calculator.dart';
import 'package:atelier/ui/eaves_storage_calculator.dart';
import 'package:atelier/ui/gestures_screen.dart';
import 'package:atelier/ui/wood_finish_calculator.dart';
import 'package:atelier/ui/work_sheet_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  test('la fiche se construit en PDF, pleine ou presque vide', () async {
    final vText = AppLocalizationsFr();
    final vFull = await buildWorkSheetPdf(vText, (
      title: 'Faux plafond',
      intro: 'Abaisser un plafond trop haut.',
      measures: [('Longueur (cm)', '500'), ('Largeur (cm)', '400')],
      results: ['96 cm de vide'],
      buy: const [ExtraItem(name: 'Fourrure 3 m', quantity: 12)],
      steps: ['Tracer au laser', 'Visser la cornière'],
    ));
    expect(String.fromCharCodes(vFull.take(5)), '%PDF-');

    final vEmpty = await buildWorkSheetPdf(vText, (
      title: 'Geste',
      intro: '',
      measures: const [],
      results: const [],
      buy: const [],
      steps: const [],
    ));
    expect(String.fromCharCodes(vEmpty.take(5)), '%PDF-');
  });

  testWidgets('les fiches s\'impriment depuis les finitions, le faux plafond, le placard et les gestes', (
    pTester,
  ) async {
    tallScreen(pTester);
    for (final vScreen in const <Widget>[
      WoodFinishCalculator(),
      DroppedCeilingCalculator(),
      EavesStorageCalculator(),
      GestureScreen(gesture: Gesture.drill),
    ]) {
      await pTester.pumpWidget(localized(vScreen));
      await pTester.pumpAndSettle();
      final vButton = pTester.widget<PrintSheetButton>(find.byType(PrintSheetButton));
      final vSheet = vButton.sheet();
      expect(vSheet.title, isNotEmpty);
      expect(vSheet.results, isNotEmpty, reason: vScreen.runtimeType.toString());
      expect(find.byTooltip('Imprimer la fiche'), findsOneWidget);
    }
  });

  testWidgets('placard impossible : pas de fiche à imprimer', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const EavesStorageCalculator()));
    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur de la façade (cm)'), '50');
    await pTester.pump();
    expect(find.byType(PrintSheetButton), findsNothing);
  });

  testWidgets('la fiche d\'un geste reprend ses étapes et ses protections', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GestureScreen(gesture: Gesture.sand)));
    await pTester.pumpAndSettle();
    final vSheet = pTester.widget<PrintSheetButton>(find.byType(PrintSheetButton)).sheet();
    expect(vSheet.steps, hasLength(3));
    expect(vSheet.results.first, 'À porter : Lunettes, Masque anti-poussière, Casque antibruit');
  });
}
