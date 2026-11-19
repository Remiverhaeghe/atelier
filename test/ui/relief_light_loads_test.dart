import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/load_explained_screen.dart';
import 'package:atelier/ui/stair_calculator.dart';
import 'package:atelier/ui/stair_relief_card.dart';
import 'package:atelier/ui/sun_light_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

Future<void> openTile(WidgetTester pTester, String pTitle) async {
  tallScreen(pTester);
  await pTester.pumpWidget(localized(const CalculatorsScreen()));
  await scrollToTile(pTester, pTitle);
  await pTester.tap(find.text(pTitle));
  await pTester.pumpAndSettle();
}

void main() {
  testWidgets('escalier en relief : échappée, puis on se cogne sous une trémie trop courte', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const StairCalculator()));

    expect(find.byType(StairSketch), findsOneWidget);
    expect(find.text('Giron de 28 cm, marches de 17,5 cm de haut'), findsOneWidget);
    expect(find.textContaining('dernière marche sous le plancher : 190 cm'), findsOneWidget);

    final vTremie = find.widgetWithText(
      TextField,
      'Longueur de la trémie existante (cm), si vous l\'avez',
    );
    await pTester.ensureVisible(vTremie);
    await pTester.enterText(vTremie, '250');
    await pTester.pump();
    expect(find.textContaining('dernière marche sous le plancher : 137,5 cm'), findsOneWidget);
    expect(find.textContaining('Trémie à agrandir : 308 cm'), findsOneWidget);
    expect(
      find.text('Une personne de 180 cm se cogne au plancher à partir de la marche 5'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Quart tournant'));
    await pTester.pump();
    expect(find.textContaining('ligne de foulée déroulée'), findsOneWidget);
    expect(find.byType(StairSketch), findsOneWidget);
  });

  testWidgets('soleil : tache au sol l\'été, rien l\'hiver par un toit au nord', (pTester) async {
    await openTile(pTester, 'Soleil par la fenêtre de toit');

    expect(find.byType(SunSketch), findsOneWidget);
    expect(find.textContaining('Tache au sol'), findsOneWidget);
    expect(find.textContaining('Lit ou bureau à 160 cm du mur de genou'), findsOneWidget);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Hiver'));
    await pTester.pump();
    await pTester.tap(find.widgetWithText(ChoiceChip, 'Nord'));
    await pTester.pump();
    expect(find.text('Pas de soleil par la fenêtre à cette heure'), findsOneWidget);
    expect(formatHour(13.5), '13 h 30');
    expect(formatHour(9), '9 h');
  });

  testWidgets('charges : une tablette d\'aggloméré, puis une poutre et une mezzanine', (
    pTester,
  ) async {
    await openTile(pTester, 'Charges en clair');

    expect(find.byType(LoadSketch), findsOneWidget);
    expect(find.text('Porte environ 16 kg'), findsOneWidget);
    expect(find.text('1 × carton de livres (15 kg)'), findsOneWidget);
    expect(
      find.text('Avec 1 × carton de livres (15 kg) : flèche de 3,74 mm au milieu (admise : 4 mm)'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Poutre'));
    await pTester.pumpAndSettle();
    expect(find.text('Porte environ 861 kg'), findsOneWidget);
    expect(find.text('10 × adulte (80 kg)'), findsOneWidget);

    await pTester.tap(find.text('Mezzanine'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Porte environ'), findsOneWidget);
    await pTester.tap(find.widgetWithText(ChoiceChip, 'adulte (80 kg)'));
    await pTester.pump();
    expect(find.byType(LoadSketch), findsOneWidget);
  });
}
