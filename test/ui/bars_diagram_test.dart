import 'package:atelier/logic/bar_cutting.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/bars_diagram.dart';
import 'package:atelier/ui/room_3d_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('une barre dessinée par barre du plan, hauteur comprise', (pTester) async {
    final vPlan = planBars([1200, 900, 2000, 1500], 2400, 3);

    await pTester.pumpWidget(localized(BarsDiagram(plan: vPlan)));

    expect(
      pTester.getSize(find.byType(BarsDiagram)).height,
      vPlan.bars.length * (BarsDiagram.barHeight + BarsDiagram.gap),
    );
    expect(find.bySemanticsLabel(RegExp('barres de plinthe à l.échelle')), findsOneWidget);
  });

  testWidgets('sans barre, le diagramme ne prend aucune place', (pTester) async {
    await pTester.pumpWidget(
      localized(
        const BarsDiagram(
          plan: BarPlan(bars: [], kerfMm: 3, tooLong: []),
        ),
      ),
    );

    expect(pTester.getSize(find.byType(BarsDiagram)), Size.zero);
  });

  testWidgets('la pièce en 3D apparaît avec trois murs et pas avant', (pTester) async {
    await pTester.pumpWidget(localized(Room3dCard(room: rectangleRoom())));

    expect(find.text('La pièce en 3D'), findsOneWidget);

    await pTester.pumpWidget(
      localized(
        const Room3dCard(
          room: Room(id: 'v', name: 'Vide', walls: [Wall(lengthMm: 3000)]),
        ),
      ),
    );

    expect(find.text('La pièce en 3D'), findsNothing);
  });

  testWidgets('le glissement du doigt fait tourner la pièce sans erreur', (pTester) async {
    await pTester.pumpWidget(localized(Room3dCard(room: rectangleRoom())));

    await pTester.drag(find.byType(CustomPaint).last, const Offset(120, 0));
    await pTester.pump();

    expect(pTester.takeException(), isNull);
  });
}
