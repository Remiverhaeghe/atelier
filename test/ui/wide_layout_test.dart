import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:atelier/ui/room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  void vScreen(WidgetTester pTester, Size pSize) {
    pTester.view
      ..physicalSize = pSize
      ..devicePixelRatio = 1;
    addTearDown(pTester.view.reset);
  }

  testWidgets('tablette : plan à gauche, murs à droite', (pTester) async {
    vScreen(pTester, const Size(1280, 800));
    await pTester.pumpWidget(
      localized(
        Scaffold(
          body: RoomWallsView(room: rectangleRoom(), onChanged: (_) {}),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('room-wide')), findsOneWidget);
    expect(find.byType(RoomPlan), findsOneWidget);
  });

  testWidgets('téléphone : tout dans une seule liste', (pTester) async {
    vScreen(pTester, const Size(400, 900));
    await pTester.pumpWidget(
      localized(
        Scaffold(
          body: RoomWallsView(room: rectangleRoom(), onChanged: (_) {}),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('room-wide')), findsNothing);
    expect(find.byType(RoomPlan), findsOneWidget);
  });

  testWidgets('calculs : plus de colonnes sur grand écran', (pTester) async {
    vScreen(pTester, const Size(1280, 800));
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    final vGrid = pTester.widget<GridView>(find.byType(GridView));
    final vDelegate = vGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(vDelegate.crossAxisCount, 4);
  });
}
