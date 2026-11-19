import 'package:atelier/ui/bathroom_safety_card.dart';
import 'package:atelier/ui/kitchen_calculator.dart';
import 'package:atelier/ui/kitchen_plan_card.dart';
import 'package:atelier/ui/shower_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('salle d’eau : volumes, pente du receveur, étanchéité et ventilation', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ShowerCalculator()));
    await scrollToFirst(pTester, find.byType(BathZonesSketch));
    expect(find.text("Volume 1 : 120 × 90 cm au sol, jusqu'à 225 cm de haut"), findsOneWidget);
    expect(find.text('Volume 2 : 120 × 150 cm au sol, 60 cm autour du volume 1'), findsOneWidget);

    await pTester.tap(find.text("Douche à l'italienne sans paroi"));
    await pTester.pumpAndSettle();
    expect(find.text("Volume 1 : 240 × 120 cm au sol, jusqu'à 225 cm de haut"), findsOneWidget);

    await scrollToFirst(pTester, find.textContaining('Pente de'));
    expect(find.text('Pente de 3 % sur 60 cm : bien'), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur gagnée entre le bord et la bonde (mm)'),
      '4',
    );
    await pTester.pump();
    expect(find.textContaining("trop faible, l'eau stagne"), findsOneWidget);

    await scrollToFirst(pTester, find.textContaining('Bouche de VMC'));
    expect(
      find.text('7,08 m² à étancher, environ 9,2 kg de résine, 2 pots de 5 kg'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Bouche de VMC à 30 m³/h, soit 2 fois le volume par heure ; porte détalonnée de 1 cm',
      ),
      findsOneWidget,
    );
  });

  testWidgets('cuisine : triangle d’activité, hotte et implantations', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(KitchenCalculator(rooms: [rectangleRoom()])));
    await scrollToFirst(pTester, find.byType(KitchenSketch));
    expect(find.text('Évier, plaque et réfrigérateur : 5,3 m de tour'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Évier à plaque, de centre à centre (cm)'),
      '80',
    );
    await pTester.pump();
    expect(find.textContaining('moins de 1,20 m'), findsOneWidget);

    await scrollToFirst(pTester, find.textContaining('hotte de'));
    expect(
      find.text('Pièce de 22,1 m³ : hotte de 221 m³/h au moins, soit 300 m³/h en magasin'),
      findsOneWidget,
    );
    expect(find.text('En U, sur trois murs'), findsOneWidget);
    expect(find.text('Avec un îlot central'), findsNothing);

    await pTester.tap(find.byType(DropdownButtonFormField<String?>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Salon').last);
    await pTester.pumpAndSettle();
    expect(
      find.text('Pièce de 30 m³ : hotte de 300 m³/h au moins, soit 300 m³/h en magasin'),
      findsOneWidget,
    );
    expect(find.text('En deux linéaires face à face'), findsOneWidget);
    expect(find.text('Hauteur sous plafond (cm)'), findsNothing);
  });
}
