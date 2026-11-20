import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/thermal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('températures lues sur l\'image : risque de moisissure gardé dans la reprise', (
    pTester,
  ) async {
    tallScreen(pTester);
    TouchUp? vTouchUp;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vTouchUp = await addThermalTouchUp(
              pContext,
              pImages: (_) async => null,
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Angle ou jonction froide'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text("Températures lues sur l'image"));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.widgetWithText(TextField, 'Zone froide (°C)'), '9');
    await pTester.enterText(find.widgetWithText(TextField, 'Mur à côté (°C)'), '17');
    await pTester.pumpAndSettle();

    expect(find.textContaining('Facteur de température : 0,29'), findsOneWidget);
    expect(find.textContaining('risque de moisir'), findsOneWidget);

    await pTester.tap(find.text('Ajouter aux reprises'));
    await pTester.pumpAndSettle();
    expect(vTouchUp!.note, contains('Relevé : 9 °C dans la zone, 17 °C au mur'));
  });

  testWidgets('écart trop faible entre dedans et dehors : pas de conclusion', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () => addThermalTouchUp(pContext, pImages: (_) async => null),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text("Températures lues sur l'image"));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.widgetWithText(TextField, 'Dehors (°C)'), '14');
    await pTester.enterText(find.widgetWithText(TextField, 'Zone froide (°C)'), '15');
    await pTester.enterText(find.widgetWithText(TextField, 'Mur à côté (°C)'), '18');
    await pTester.pumpAndSettle();

    expect(find.textContaining("l'image ne permet pas de conclure"), findsOneWidget);
    expect(find.textContaining('Facteur de température'), findsNothing);
  });
}
