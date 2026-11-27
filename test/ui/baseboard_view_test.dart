import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/units.dart';
import 'package:atelier/ui/baseboard_view.dart';
import 'package:atelier/ui/plan_unit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('liste des coupes, fournitures et morceaux cochés', (pTester) async {
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          BaseboardView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    expect(find.text('8 barres à acheter'), findsOneWidget);
    expect(find.text('8 morceaux, 14 m de plinthe'), findsOneWidget);
    expect(find.text('2 cartouches de colle'), findsOneWidget);

    await scrollToFirst(pTester, find.text('Mur 1 · 200 cm'));
    expect(
      find.text(
        'Début : onglet 45°, pointe longue contre le mur · Fin : biseau 45° pour joindre au '
        'morceau voisin\ndans la barre 1',
      ),
      findsWidgets,
    );

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();
    expect(vRoom.cutPieces, [0]);
    // Le compteur est juste au-dessus du premier morceau : remonter un peu pour le voir.
    await pTester.drag(verticalList(), const Offset(0, 300));
    await pTester.pump();
    expect(find.text('1 morceau coupé sur 8'), findsOneWidget);
  });

  testWidgets('la carte « Prochaine coupe » passe d\'une pièce à la suivante', (pTester) async {
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          BaseboardView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    expect(find.text('Prochaine coupe'), findsOneWidget);
    expect(find.text('200 cm'), findsOneWidget);

    await pTester.tap(find.text('Coupée, suivante'));
    await pTester.pump();

    expect(vRoom.cutPieces, [0]);
    expect(find.text('Prochaine coupe'), findsOneWidget);
  });

  testWidgets('la prochaine coupe donne la barre et suit l\'unité choisie', (pTester) async {
    await pTester.pumpWidget(
      PlanUnit(
        unit: FieldUnit.mm,
        child: localized(BaseboardView(room: rectangleRoom(), onChanged: (_) {})),
      ),
    );

    expect(find.text('2000 mm'), findsWidgets);
    expect(find.textContaining('Barre 1 : '), findsOneWidget);
  });

  testWidgets('sans murs, la vue demande de saisir la pièce', (pTester) async {
    await pTester.pumpWidget(
      localized(
        BaseboardView(
          room: const Room(id: 'r', name: 'R'),
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.textContaining('Saisis d\'abord les murs'), findsOneWidget);
  });

  testWidgets('les morceaux et les barres suivent l\'unité choisie dans les réglages', (
    pTester,
  ) async {
    final vRoom = rectangleRoom();
    await pTester.pumpWidget(
      PlanUnit(
        unit: FieldUnit.mm,
        child: localized(BaseboardView(room: vRoom, onChanged: (_) {})),
      ),
    );

    await scrollToFirst(pTester, find.text('Mur 1 · 2000 mm'));

    // Le mur de 4 m est coupé en deux morceaux de 2 m : deux lignes portent ce titre
    expect(find.text('Mur 1 · 2000 mm'), findsWidgets);
    expect(find.text('Mur 1 · 200 cm'), findsNothing);
  });
}
