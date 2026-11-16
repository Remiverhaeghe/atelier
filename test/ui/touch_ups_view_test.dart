import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
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
}
