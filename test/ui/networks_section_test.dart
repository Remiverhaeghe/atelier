import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/networks_section.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('un câble relevé, puis « puis-je percer ici ? »', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          SingleChildScrollView(
            child: Column(
              children: [
                RoomPlan(room: vRoom),
                NetworksSection(room: vRoom, onChanged: (pNew) => pSetState(() => vRoom = pNew)),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('Relevez les gaines'), findsOneWidget);

    await pTester.tap(find.text('Relever un réseau'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Longueur invalide.'), findsOneWidget);
    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    for (final (vIndex, vValue) in [(0, '100'), (1, '30'), (2, '100'), (3, '110')]) {
      await pTester.enterText(vFields.at(vIndex), vValue);
    }
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom.networks.single.toHeightMm, 1100);
    expect(find.text('Électricité, Mur 1'), findsOneWidget);

    await pTester.tap(find.text('Puis-je percer ici ?'));
    await pTester.pumpAndSettle();
    final vDrill = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vDrill.at(0), '105');
    await pTester.enterText(vDrill.at(1), '70');
    await pTester.pump();
    expect(find.text('Non : Électricité relevé à 5 cm'), findsOneWidget);

    await pTester.enterText(vDrill.at(0), '200');
    await pTester.enterText(vDrill.at(1), '120');
    await pTester.pump();
    expect(find.textContaining('Aucun réseau relevé à moins de 10 cm'), findsOneWidget);
    await pTester.tap(find.text('Fermer'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vRoom.networks, isEmpty);
  });
}
