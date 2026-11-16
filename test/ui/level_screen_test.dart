import 'dart:async';

import 'package:atelier/logic/level.dart';
import 'package:atelier/ui/level_screen.dart';
import 'package:atelier/ui/slope_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('niveau : de niveau à plat, pente affichée une fois penché', (pTester) async {
    final vGravity = StreamController<Gravity>(sync: true);
    addTearDown(vGravity.close);
    await pTester.pumpWidget(localized(LevelScreen(gravity: vGravity.stream)));

    for (var vIndex = 0; vIndex < 15; vIndex++) {
      vGravity.add((x: 0, y: 0, z: 9.81));
    }
    await pTester.pump();
    expect(find.text('De niveau'), findsOneWidget);

    for (var vIndex = 0; vIndex < 15; vIndex++) {
      vGravity.add((x: 0, y: 0.1712, z: 9.8085));
    }
    await pTester.pump();
    expect(find.text('Pente de 1,7 %'), findsOneWidget);
    expect(find.text('Utiliser cet angle'), findsNothing);
  });

  testWidgets('rampant mesuré au téléphone : la largeur au sol suit l\'angle', (pTester) async {
    tallScreen(pTester);
    final vGravity = StreamController<Gravity>.broadcast(sync: true);
    addTearDown(vGravity.close);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          SingleChildScrollView(
            child: SlopeEditor(
              room: vRoom,
              gravity: vGravity.stream,
              onChanged: (pNew) => pSetState(() => vRoom = pNew),
            ),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('Plafond rampant'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Mesurer l\'angle du rampant au téléphone'));
    await pTester.pumpAndSettle();
    vGravity.add((x: 0, y: 5.886, z: 7.848));
    await pTester.pump();
    expect(find.text('36,9°'), findsOneWidget);
    await pTester.tap(find.text('Utiliser cet angle'));
    await pTester.pumpAndSettle();

    // Jambette d'1 m sous un plafond de 2,50 m : 1,50 m à monter sur 36,9°
    expect(vRoom.slope!.runMm, 1998);
    expect(find.text('Angle de 36,9° : 199,8 cm au sol'), findsOneWidget);
  });
}
