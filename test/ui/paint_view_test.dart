import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/paint_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('on choisit les surfaces, les litres et les pots suivent', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) =>
            localized(PaintView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom))),
      ),
    );
    expect(find.textContaining('Rien à peindre'), findsOneWidget);

    await pTester.tap(find.text('Murs'));
    await pTester.pump();
    expect(vRoom.paint.walls, isTrue);
    // 14 m × 2,5 m, deux couches à 10 m²/L, 10 % de marge : 7,7 L, un pot de 10 L
    expect(find.text('35 m² de murs'), findsOneWidget);
    expect(find.text('Peinture murs : 7,7 L, soit 1 × 10 L'), findsOneWidget);

    await pTester.tap(find.text('Plafond'));
    await pTester.pump();
    expect(find.text('Plafond : 12 m²'), findsOneWidget);
    expect(find.textContaining('Peinture plafond : 2,6 L'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur sous plafond (cm)'), '270');
    await pTester.pump();
    expect(vRoom.ceilingHeightMm, 2700);
    expect(find.text('37,8 m² de murs'), findsOneWidget);
  });

  testWidgets('sans murs, la vue demande de saisir la pièce', (pTester) async {
    await pTester.pumpWidget(
      localized(
        PaintView(
          room: const Room(id: 'r', name: 'R'),
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.textContaining('Saisis d\'abord les murs'), findsOneWidget);
  });

  testWidgets('les prix saisis choisissent les pots les moins chers', (pTester) async {
    tallScreen(pTester);
    final vRoom = rectangleRoom().copyWith(paint: const PaintSettings(walls: true));
    await pTester.pumpWidget(
      localized(
        PaintView(
          room: vRoom,
          onChanged: (_) {},
          prices: const {'paintWalls10': 80, 'paintWalls5': 30, 'paintWalls2': 18},
        ),
      ),
    );

    expect(find.text('Peinture murs : 7,7 L, soit 2 × 5 L'), findsOneWidget);
  });

  testWidgets('couleurs : murs choisis, puis accords proposés pour le plafond', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom().copyWith(paint: const PaintSettings(walls: true, ceiling: true));
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          PaintView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    await pTester.tap(find.text('Pas encore choisie').first);
    await pTester.pumpAndSettle();
    await pTester.tap(find.bySemanticsLabel('#A7B8A0'));
    await pTester.pumpAndSettle();
    expect(vRoom.paint.wallColor, 0xA7B8A0);

    await pTester.tap(find.text('Pas encore choisie').first);
    await pTester.pumpAndSettle();
    expect(find.text('Même teinte très claire, pour le plafond'), findsOneWidget);
    await pTester.tap(find.bySemanticsLabel('#F3EFE6'));
    await pTester.pumpAndSettle();
    expect(vRoom.paint.ceilingColor, 0xF3EFE6);
  });
}
