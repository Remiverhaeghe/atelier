import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/room_sketch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

/// Ouvre l'écran de dessin depuis un bouton ; la fonction rendue donne la pièce renvoyée.
Future<Room? Function()> openSketch(WidgetTester pTester, Room pRoom) async {
  Room? vResult;
  await pTester.pumpWidget(
    localized(
      Builder(
        builder: (pContext) => TextButton(
          onPressed: () async {
            vResult = await sketchRoom(pContext, pRoom);
          },
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );

  await pTester.tap(find.text('ouvrir'));
  await pTester.pumpAndSettle();

  return () => vResult;
}

Future<void> typeWall(WidgetTester pTester, String pLength) async {
  await pTester.enterText(find.widgetWithText(TextField, 'Longueur (cm)'), pLength);
  await pTester.tap(find.text('Mur suivant'));
  await pTester.pumpAndSettle();
}

void main() {
  const vRoom = Room(id: 'p', name: 'Chambre fictive');

  testWidgets('rectangle : deux murs tapés, les deux autres déduits, hauteur gardée', (
    pTester,
  ) async {
    tallScreen(pTester);
    final vResult = await openSketch(pTester, vRoom);

    expect(find.text('Mur 1 : mesure du coin A au coin B'), findsOneWidget);
    await typeWall(pTester, '420');
    expect(find.text('Mur 2 : mesure du coin B au coin C'), findsOneWidget);
    await typeWall(pTester, '3,1 m');
    expect(find.text('2 murs mesurés sur 4'), findsOneWidget);
    expect(find.textContaining('Déduit des autres murs : 420 cm'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur sous plafond (cm)'), '245');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vRoomDrawn = vResult()!;
    expect(vRoomDrawn.walls.map((pWall) => pWall.lengthMm), [4200, 3100, 4200, 3100]);
    expect(vRoomDrawn.walls.map((pWall) => pWall.angleToNextDeg), everyElement(90));
    expect(vRoomDrawn.ceilingHeightMm, 2450);
    expect(vRoomDrawn.closed, isTrue);
  });

  testWidgets('toucher un mur du plan le choisit', (pTester) async {
    tallScreen(pTester);
    await openSketch(pTester, vRoom);

    // Le rectangle par défaut fait 4 m sur 3 : le mur 3 est le bord du haut
    final vBox = pTester.getRect(find.byType(ShapeSketch));
    final vScale = [
      (vBox.width - 72) / 4000,
      (vBox.height - 72) / 3000,
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vTop = (vBox.height - 3000 * vScale) / 2;
    await pTester.tapAt(Offset(vBox.center.dx, vBox.top + vTop));
    await pTester.pumpAndSettle();

    expect(find.text('Mur 3 : mesure du coin C au coin D'), findsOneWidget);
  });

  testWidgets('murs d\'en face différents : la diagonale donne les angles', (pTester) async {
    tallScreen(pTester);
    await openSketch(pTester, vRoom);
    for (final vLength in ['400', '300', '405', '300']) {
      await typeWall(pTester, vLength);
    }

    expect(find.textContaining("pas tout à fait d'équerre"), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Diagonale du coin A au coin C (cm)'),
      '502',
    );
    await pTester.pumpAndSettle();
    expect(find.textContaining('Angles calculés : B '), findsOneWidget);
  });

  testWidgets('en L : six murs numérotés', (pTester) async {
    tallScreen(pTester);
    await openSketch(pTester, vRoom);
    await pTester.tap(find.text('En L'));
    await pTester.pumpAndSettle();

    expect(find.text('0 murs mesurés sur 6'), findsOneWidget);
  });
}
