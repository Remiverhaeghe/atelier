import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/parquet_view.dart';
import 'package:atelier/ui/quick_walls_screen.dart';
import 'package:atelier/ui/shopping_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('pièce rectangulaire en deux cotes, puis passage en mètres', (pTester) async {
    tallScreen(pTester);
    List<Wall>? vWalls;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async =>
                vWalls = await editAllWalls(pContext, const Room(id: 'r', name: 'Bureau')),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Pièce rectangulaire'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.widgetWithText(TextField, 'Longueur'), '400');
    await pTester.enterText(find.widgetWithText(TextField, 'Largeur'), '3 m');
    await pTester.pumpAndSettle();
    await pTester.tap(find.widgetWithText(FilledButton, 'Enregistrer'));
    await pTester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Mur 4'), findsOneWidget);
    expect(find.textContaining('Le contour se referme'), findsOneWidget);

    await pTester.tap(find.text('m').first);
    await pTester.pumpAndSettle();
    expect(find.text('4'), findsNWidgets(2));
    await pTester.enterText(find.widgetWithText(TextField, 'Mur 1'), '4,2');
    await pTester.pumpAndSettle();
    // Quatre murs qui ne forment pas un rectangle : les angles se calculent tout seuls.
    expect(find.textContaining('angles calculés tout seuls'), findsOneWidget);
    expect(find.textContaining('Le contour se referme'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Mur 3'), '4,2');
    await pTester.pumpAndSettle();
    expect(find.textContaining('angles calculés tout seuls'), findsNothing);

    await pTester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vWalls!.map((pWall) => pWall.lengthMm), [4200, 3000, 4200, 3000]);
  });

  testWidgets('un coin sortant se choisit d\'un geste, un mur se retire', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(QuickWallsScreen(room: rectangleRoom())));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Coin sortant').first);
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '270'), findsOneWidget);

    await pTester.tap(find.byTooltip('Retirer ce mur').last);
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Mur 4'), findsNothing);
  });

  testWidgets('une cote d\'une pièce du chantier se reprend dans un calcul', (pTester) async {
    double? vValue;
    await pTester.pumpWidget(
      localized(
        ShoppingTarget(
          worksites: [
            Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
          ],
          add: (String pId, List<ExtraItem> pItems) async {},
          child: NumberField<double>(
            label: 'Longueur de la pièce (mm)',
            initial: '',
            parse: (pText) => double.tryParse(pText),
            onValue: (pValue) => vValue = pValue,
          ),
        ),
      ),
    );
    await pTester.tap(find.byTooltip("Reprendre une cote d'une pièce"));
    await pTester.pumpAndSettle();
    expect(find.text('Salon'), findsOneWidget);
    expect(find.text('Sol : 12 m²'), findsNothing);
    await pTester.tap(find.text('Longueur : 4000 mm'));
    await pTester.pumpAndSettle();
    expect(vValue, 4000);

    await pTester.enterText(find.byType(TextField), '2,5 m');
    await pTester.pumpAndSettle();
    expect(vValue, 2500);
  });
}
