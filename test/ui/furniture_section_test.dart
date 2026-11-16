import 'package:atelier/logic/furniture.dart';
import 'package:atelier/ui/furniture_section.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('un meuble se pose, se tourne, signale ce qui gêne puis s\'enlève', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          SingleChildScrollView(
            child: Column(
              children: [
                RoomPlan(room: vRoom),
                FurnitureSection(room: vRoom, onChanged: (pNew) => pSetState(() => vRoom = pNew)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Posez un meuble'), findsOneWidget);

    await pTester.tap(find.text('Ajouter un meuble'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Bureau'));
    await pTester.pumpAndSettle();
    await pTester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(RoomPlan)),
    );
    await pTester.pumpAndSettle();
    expect(vRoom.furniture.single.kind, FurnitureKind.desk);

    // Au milieu d'une pièce de 3 m de large, 60 cm de profondeur : 1,20 m de chaque côté
    expect(find.byIcon(Icons.warning_amber), findsNothing);

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Tourner d\'un quart de tour'));
    await pTester.pumpAndSettle();
    expect(vRoom.furniture.single.turned, isTrue);

    await pTester.tap(find.byType(PopupMenuButton<String>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vRoom.furniture, isEmpty);
  });
}
