import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('étagère : la liste de débit suit la saisie, la portée est surveillée', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Étagère sur mesure'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Étagère sur mesure'));
    await pTester.pumpAndSettle();

    expect(find.text('5 × tablette de 76,4 × 30 cm'), findsOneWidget);
    expect(find.textContaining('Tablette trop large'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Largeur (cm)'), '60');
    await pTester.pump();
    expect(find.text('5 × tablette de 56,4 × 30 cm'), findsOneWidget);
    expect(find.textContaining('Tablette trop large'), findsNothing);
  });

  testWidgets('étagère : épaisseur selon la charge, assemblage et tenue au mur', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text('Étagère sur mesure'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Étagère sur mesure'));
    await pTester.pumpAndSettle();

    // Aggloméré de 18 mm, 76,4 cm entre montants, livres
    expect(find.text('Épaisseur conseillée pour cette charge : 22 mm'), findsOneWidget);
    expect(find.textContaining("3 vis d'assemblage"), findsOneWidget);
    expect(find.textContaining('anti-basculement'), findsOneWidget);
    expect(find.textContaining('se met en losange'), findsNothing);

    await pTester.tap(find.text('Tablettes réglables sur taquets'));
    await pTester.pump();
    expect(find.textContaining('Quatre taquets'), findsOneWidget);

    await pTester.tap(find.text('Fond cloué au dos'));
    await pTester.pump();
    expect(find.textContaining('se met en losange'), findsOneWidget);
  });
}
