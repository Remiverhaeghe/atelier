import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/photo_annotator.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:atelier/ui/touch_ups_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

/// Vue des reprises sur une pièce qui change à chaque modification.
Future<Room Function()> pumpView(WidgetTester pTester, Room pRoom) async {
  var vRoom = pRoom;
  await pTester.pumpWidget(
    StatefulBuilder(
      builder: (pContext, pSetState) => localized(
        TouchUpsView(
          room: vRoom,
          onChanged: (pNew) => pSetState(() => vRoom = pNew),
          photos: (pId) async => '/photos/$pId.jpg',
        ),
      ),
    ),
  );

  return () => vRoom;
}

void main() {
  testWidgets('dans une zone sans murs, on enchaîne les reprises puis on coche', (pTester) async {
    final vRoom = await pumpView(pTester, const Room(id: 't', name: 'Toit'));
    expect(find.textContaining('Rien à reprendre'), findsOneWidget);

    await pTester.tap(find.text('Ajouter une reprise'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField).at(0), 'Nettoyage tuile');
    await pTester.enterText(find.byType(TextField).at(1), '5');
    await pTester.tap(find.text('Reprise suivante'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField).at(0), 'Reprise toit');
    await pTester.enterText(find.byType(TextField).at(3), 'Tuiles');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(vRoom().touchUps.map((pTouchUp) => pTouchUp.label), ['Nettoyage tuile', 'Reprise toit']);
    expect(vRoom().touchUps.first.passes, 5);
    expect(find.text('Tuiles'), findsOneWidget);

    // Cocher la 3e case du nettoyage compte trois passages
    await pTester.tap(find.byType(Checkbox).at(2));
    await pTester.pump();
    expect(vRoom().touchUps.first.donePasses, 3);
    expect(find.text('3 passages faits sur 6'), findsOneWidget);
  });

  testWidgets('une saisie vide est refusée', (pTester) async {
    await pumpView(pTester, const Room(id: 't', name: 'Toit'));
    await pTester.tap(find.text('Ajouter une reprise'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField).at(1), '0');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    expect(find.text('Dis en quelques mots ce qu\'il faut faire'), findsOneWidget);
    expect(find.text('Au moins un passage'), findsOneWidget);
  });

  testWidgets('la reprise se place sur le plan, prend une photo et se modifie', (pTester) async {
    // Écran haut : le plan et la reprise tiennent ensemble, sans défilement
    pTester.view.physicalSize = const Size(800, 2000);
    pTester.view.devicePixelRatio = 1;
    addTearDown(pTester.view.reset);
    final vRoom = await pumpView(
      pTester,
      rectangleRoom().copyWith(
        touchUps: const [TouchUp(id: 'e', label: 'Enduit', passes: 2)],
      ),
    );

    await pTester.tap(find.byIcon(Icons.more_vert));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Placer sur le plan'));
    await pTester.pumpAndSettle();
    expect(find.text('Touche le plan à l\'endroit de la reprise'), findsOneWidget);
    await pTester.tap(find.byType(RoomPlan));
    await pTester.pump();
    expect(vRoom().touchUps.single.hasMarker, isTrue);
    // Le centre du plan tombe au milieu de la pièce de 400 × 300 cm
    expect(vRoom().touchUps.single.markerXMm, closeTo(2000, 50));
    expect(vRoom().touchUps.single.markerYMm, closeTo(1500, 50));

    await pTester.tap(find.byIcon(Icons.more_vert));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Prendre une photo'));
    await pTester.pumpAndSettle();
    expect(vRoom().touchUps.single.photoPath, '/photos/e.jpg');

    await pTester.tap(find.text('Enduit'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField).at(0), 'Enduit de lissage');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom().touchUps.single.label, 'Enduit de lissage');

    await pTester.tap(find.byIcon(Icons.more_vert));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Retirer du plan'));
    await pTester.pumpAndSettle();
    expect(vRoom().touchUps.single.hasMarker, isFalse);

    await pTester.tap(find.byIcon(Icons.more_vert));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vRoom().touchUps, isEmpty);
  });

  testWidgets('un relevé thermique devient une reprise avec sa préconisation', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpView(pTester, const Room(id: 't', name: 'Chambre'));

    await pTester.tap(find.text('Relevé thermique'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Porte'));
    await pTester.pump();
    expect(find.textContaining('bas de porte'), findsOneWidget);
    await pTester.tap(find.text('Image de la caméra'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Ajouter aux reprises'));
    await pTester.pumpAndSettle();

    final vTouchUp = vRoom().touchUps.single;
    expect(vTouchUp.label, 'Porte');
    expect(vTouchUp.toBuy, 'Bas de porte et joint');
    expect(vTouchUp.photoPath, startsWith('/photos/'));
  });

  testWidgets('contrôle de finition : photo, cercles, reprise créée', (pTester) async {
    tallScreen(pTester);
    final vRoom = await pumpView(pTester, const Room(id: 's', name: 'Salon'));

    await pTester.tap(find.text('Contrôle de finition'));
    await pTester.pumpAndSettle();
    expect(find.text('Entourer sur la photo'), findsOneWidget);
    await pTester.tapAt(pTester.getCenter(find.byType(MarkedPhoto)));
    await pTester.pump();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vTouchUp = vRoom().touchUps.single;
    expect(vTouchUp.label, 'À reprendre d\'après la photo');
    expect(vTouchUp.photoMarks.single.x, closeTo(0.5, 0.01));
    expect(find.text('1 endroit entouré sur la photo'), findsOneWidget);
  });

  testWidgets('relevé thermique d\'une pièce à plexis : rappel et cadre à préparer', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pumpView(
      pTester,
      const Room(
        id: 'c',
        name: 'Combles',
        fixtures: [
          Fixture(
            id: 'p',
            kind: FixtureKind.roofWindow,
            xMm: 0,
            yMm: 0,
            widthMm: 780,
            depthMm: 980,
            plexi: true,
          ),
        ],
      ),
    );

    await pTester.tap(find.text('Relevé thermique'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('1 plexi de toit dans la pièce (0,76 m²)'), findsOneWidget);
    await pTester.tap(find.textContaining('1 plexi de toit'));
    await pTester.pumpAndSettle();
    expect(find.text('2 montants de 97 cm'), findsOneWidget);
  });

  testWidgets('le matériel des reprises part dans la liste de courses', (pTester) async {
    tallScreen(pTester);
    final vAdded = <ExtraItem>[];
    await pTester.pumpWidget(
      localized(
        TouchUpsView(
          room: rectangleRoom().copyWith(
            touchUps: const [TouchUp(id: 't', label: 'Fissure', toBuy: '2 × bande, enduit')],
          ),
          onChanged: (_) {},
          shopping: const [ExtraItem(name: 'Enduit', quantity: 1)],
          onAddToShopping: vAdded.addAll,
        ),
      ),
    );
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Ajouter 1 article aux courses'));
    await pTester.pump();
    expect([for (final vItem in vAdded) (vItem.name, vItem.quantity)], [('bande', 2)]);
    expect(find.text('Ajouté à la liste de courses : 2 × bande'), findsOneWidget);
  });
}
