import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/energy_diagnosis_screen.dart';
import 'package:atelier/ui/renovation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('diagnostic thermique : pertes par paroi, travaux classés, puis pas à pas', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Diagnostic thermique');
    await pTester.tap(find.text('Diagnostic thermique'));
    await pTester.pumpAndSettle();

    expect(find.byType(HouseLossSketch), findsOneWidget);
    expect(find.text('Environ 23100 kWh perdus par an'), findsOneWidget);
    expect(find.text('Murs : 48 % des pertes (210 W/K)'), findsOneWidget);
    expect(
      find.text('1. Murs vers « Bien isolés (12 cm et plus) » : 42 % des pertes en moins, environ 8400 €'),
      findsOneWidget,
    );
    expect(find.textContaining('France Rénov'), findsOneWidget);

    // Murs déjà bien isolés : ils sortent des travaux
    await scrollToFirst(pTester, find.byKey(const ValueKey('etat-walls')));
    await pTester.tap(find.byKey(const ValueKey('etat-walls')));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Bien isolés (12 cm et plus)').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('1. Murs vers'), findsNothing);

    await scrollToFirst(pTester, find.widgetWithText(FilledButton, 'Rénovation pas à pas'));
    await pTester.tap(find.widgetWithText(FilledButton, 'Rénovation pas à pas'));
    await pTester.pumpAndSettle();
    expect(find.text('1. Toit et combles'), findsOneWidget);
    expect(find.text('Facture : environ 15 % de moins'), findsOneWidget);
    expect(find.text('Déjà à un bon niveau : rien à gagner ici'), findsOneWidget);
  });

  testWidgets('rénovation pas à pas : un chauffage moins bon n’est pas compté', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RenovationScreen()));
    expect(find.text('1. Toit et combles'), findsOneWidget);
    expect(find.text('Facture : environ 10 % de moins'), findsOneWidget);
    expect(find.text('Il reste environ 90 % de la facture de départ'), findsOneWidget);
    expect(find.text('Facture : un peu moins, moins de 5 %'), findsOneWidget);

    await pTester.tap(find.byKey(const ValueKey('Chauffage après travaux')));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Poêle à bois').last);
    await pTester.pumpAndSettle();
    expect(find.text('Déjà à un bon niveau : rien à gagner ici'), findsOneWidget);
  });

  testWidgets('les pièces du chantier donnent sol, toit et volume', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(EnergyDiagnosisScreen(rooms: [rectangleRoom()])));
    await scrollToFirst(pTester, find.textContaining('repris des pièces saisies'));
    expect(find.textContaining('repris des pièces saisies'), findsOneWidget);
    expect(find.widgetWithText(TextField, '12'), findsNWidgets(2));
    expect(find.widgetWithText(TextField, '30'), findsOneWidget);
  });
}
