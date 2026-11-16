import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/baseboard_view.dart';
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

    expect(find.text('8 morceaux, 14 m de plinthe'), findsOneWidget);
    expect(find.text('2 cartouches de colle'), findsOneWidget);

    await pTester.scrollUntilVisible(find.text('Mur 1 · 200 cm').first, 200);
    expect(
      find.text(
        'Début : onglet 45°, pointe longue contre le mur · Fin : biseau 45° pour joindre au morceau voisin',
      ),
      findsOneWidget,
    );

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();
    expect(vRoom.cutPieces, [0]);
    expect(find.text('1 morceau coupé sur 8'), findsOneWidget);
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
}
