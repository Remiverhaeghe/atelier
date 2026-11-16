import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/dialogs.dart';
import 'package:atelier/ui/fixtures_section.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

/// Section des éléments sur une pièce qui change à chaque modification.
Future<Room Function()> pumpSection(WidgetTester pTester, Room pRoom) async {
  var vRoom = pRoom;
  await pTester.pumpWidget(
    StatefulBuilder(
      builder: (pContext, pSetState) => localized(
        SingleChildScrollView(
          child: FixturesSection(room: vRoom, onChanged: (pNew) => pSetState(() => vRoom = pNew)),
        ),
      ),
    ),
  );

  return () => vRoom;
}

/// Choisit l'élément dans la liste puis touche le milieu du plan.
Future<void> addFixture(WidgetTester pTester, String pLabel) async {
  await pTester.tap(find.text('Ajouter un élément'));
  await pTester.pumpAndSettle();
  await pTester.tap(find.text(pLabel));
  await pTester.pumpAndSettle();
  await pTester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(RoomPlan)));
  await pTester.pumpAndSettle();
}

void main() {
  testWidgets('une prise se place en deux gestes, puis devient un bloc de deux', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpSection(pTester, rectangleRoom());
    expect(find.textContaining('choisissez'), findsOneWidget);

    await addFixture(pTester, 'Prise');
    final vSocket = vRoom().fixtures.single;
    expect(vSocket.kind, FixtureKind.socket);
    // Le milieu du plan tombe au milieu de la pièce de 4 × 3 m
    expect(vSocket.xMm, closeTo(2000, 200));
    expect(vSocket.yMm, closeTo(1500, 200));
    expect(find.text('1 prise, aucun interrupteur'), findsOneWidget);

    await pTester.tap(find.text('Prise'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), '2');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures.single.count, 2);
    expect(find.text('Bloc de 2'), findsOneWidget);
  });

  testWidgets('escalier : taille proposée et marches calculées', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpSection(pTester, rectangleRoom());

    await addFixture(pTester, 'Escalier');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vStairs = vRoom().fixtures.single;
    expect(vStairs.riseMm, 2700);
    expect(vStairs.depthMm, 3000);
    expect(find.textContaining('15 marches'), findsOneWidget);
  });

  testWidgets('fenêtre de toit : une taille vide est refusée', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpSection(pTester, rectangleRoom());

    await addFixture(pTester, 'Fenêtre de toit');
    await pTester.enterText(find.byType(TextField).first, '');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures, isEmpty);

    await pTester.enterText(find.byType(TextField).first, '78');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('retirée du plafond'), findsOneWidget);
  });

  testWidgets('on déplace puis on supprime un élément', (pTester) async {
    tallScreen(pTester);
    const vMezzanine = Fixture(
      id: 'm',
      kind: FixtureKind.mezzanine,
      xMm: 100,
      yMm: 100,
      widthMm: 2000,
      depthMm: 1500,
    );
    final vRoom = await pumpSection(pTester, rectangleRoom().copyWith(fixtures: [vMezzanine]));
    expect(find.textContaining('Second niveau de 3'), findsOneWidget);

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Déplacer'));
    await pTester.pumpAndSettle();
    await pTester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(RoomPlan)),
    );
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures.single.xMm, closeTo(2000, 200));

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures, isEmpty);
  });

  testWidgets('la saisie d\'un mur dit entre quels coins mesurer', (pTester) async {
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () => editWall(
              pContext,
              pNumber: 4,
              pWall: rectangleRoom().walls.last,
              pRoom: rectangleRoom(),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();

    expect(find.textContaining('du coin D au coin A'), findsOneWidget);
    expect(find.text('Angle au coin A (°)'), findsOneWidget);
  });

  testWidgets('mezzanine avec la hauteur de son plancher, escalier jusqu\'à elle', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpSection(pTester, rectangleRoom().copyWith(ceilingHeightMm: 5500));

    await addFixture(pTester, 'Mezzanine');
    await pTester.enterText(find.byType(TextField).at(2), '270');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures.single.riseMm, 2700);
    expect(find.textContaining('à 270 cm du sol'), findsOneWidget);

    await addFixture(pTester, 'Escalier');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom().fixtures.last.riseMm, 2700);
  });
}
