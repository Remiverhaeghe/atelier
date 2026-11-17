import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('mezzanine : solives, poutre et poteaux suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Mezzanine'));
    await pTester.pumpAndSettle();

    // 3 × 2 m contre un mur, chambre
    expect(find.text('9 solives de 45 × 145 mm en C24, tous les 40 cm'), findsOneWidget);
    expect(find.textContaining('1 poutre en lamellé-collé de 90 × 225 mm'), findsOneWidget);
    expect(find.textContaining('2 poteaux de 100 × 100 mm'), findsOneWidget);
    expect(find.textContaining('18 sabots'), findsOneWidget);
    expect(find.text('6 bois de 45 × 145 mm en 450 cm'), findsOneWidget);
    expect(find.text('À couper : 1 × 300 cm, 9 × 200 cm'), findsOneWidget);
    expect(find.textContaining('4 panneaux de 18 mm'), findsOneWidget);
    expect(find.textContaining('630 cm de bord dans le vide, 7 poteaux'), findsOneWidget);
    expect(find.textContaining('42 barreaux verticaux'), findsOneWidget);

    expect(find.textContaining("Donne la largeur et la longueur de l'ouverture"), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Trémie : largeur, en travers des solives (cm)'),
      '90',
    );
    await pTester.enterText(
      find.widgetWithText(TextField, 'Trémie : longueur, dans le sens des solives (cm)'),
      '100',
    );
    await pTester.pump();
    expect(find.textContaining('2 solives coupées : solives boiteuses de 100 cm'), findsOneWidget);
    expect(find.text('4 sabots : deux pour le chevêtre, un par solive boiteuse'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Profondeur, portée des solives (cm)'),
      '350',
    );
    await pTester.pump();
    expect(find.text('9 solives de 45 × 170 mm en C24, tous les 40 cm'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Profondeur, portée des solives (cm)'),
      '800',
    );
    await pTester.pump();
    expect(find.textContaining('Portée trop grande'), findsOneWidget);
  });

  testWidgets('mezzanine : hauteur dans une pièce haute, poteaux et escalier', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.tap(find.text('Mezzanine'));
    await pTester.pumpAndSettle();

    expect(find.text('Hauteur dans la pièce'), findsNothing);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur sous plafond de la pièce (cm)'),
      '500',
    );
    await pTester.pump();
    expect(find.textContaining('Dessus du plancher à 244,3 cm du sol'), findsOneWidget);
    expect(find.textContaining('on tient debout partout'), findsOneWidget);

    // Poteaux saisis à 250 cm : la répartition propose de les ramener à 220 cm
    expect(find.text('Poteaux de 220 cm'), findsNothing);
    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur des poteaux (cm)'), '250');
    await pTester.pump();
    await pTester.ensureVisible(find.text('Poteaux de 220 cm'));
    await pTester.tap(find.text('Poteaux de 220 cm'));
    await pTester.pump();
    expect(find.text('Poteaux de 220 cm'), findsNothing);

    await pTester.tap(find.text("Escalier jusqu'à ce plancher"));
    await pTester.pumpAndSettle();
    expect(find.text('Escalier droit'), findsWidgets);
  });
}
