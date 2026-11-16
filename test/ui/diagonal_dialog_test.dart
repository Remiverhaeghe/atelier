import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/diagonal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

/// Ouvre le contrôle sur [pRoom] et garde la pièce renvoyée.
Future<Room? Function()> openCheck(WidgetTester pTester, Room pRoom) async {
  Room? vResult;
  await pTester.pumpWidget(
    localized(
      Builder(
        builder: (pContext) => TextButton(
          onPressed: () async => vResult = await checkDiagonal(pContext, pRoom),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );
  await pTester.tap(find.text('ouvrir'));
  await pTester.pumpAndSettle();

  return () => vResult;
}

void main() {
  testWidgets('diagonale conforme : rien à corriger', (pTester) async {
    await openCheck(pTester, rectangleRoom());
    expect(find.textContaining('du coin A au coin C'), findsOneWidget);
    expect(find.text("D'après le plan : 500 cm"), findsOneWidget);

    await pTester.enterText(find.byType(TextField), '500,5');
    await pTester.pump();
    expect(find.text('Le plan et la pièce concordent.'), findsOneWidget);
    expect(find.text('Corriger les angles'), findsNothing);
  });

  testWidgets('murs opposés différents, angles corrigés par la diagonale', (pTester) async {
    final vWalls = [...rectangleRoom().walls]..[2] = const Wall(lengthMm: 4030);
    final vResult = await openCheck(pTester, rectangleRoom().copyWith(walls: vWalls));
    expect(find.textContaining('Murs 1 et 3 : 3 cm'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), '512');
    await pTester.pump();
    expect(find.textContaining("un angle n'est pas celui saisi"), findsOneWidget);
    await pTester.tap(find.text('Corriger les angles'));
    await pTester.pumpAndSettle();

    final vAngles = [for (final vWall in vResult()!.walls) vWall.angleToNextDeg];
    expect(vAngles.first, greaterThan(90));
    expect(vAngles.reduce((pA, pB) => pA + pB), closeTo(360, 1));
  });
}
