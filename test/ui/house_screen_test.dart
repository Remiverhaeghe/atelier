import 'dart:math' as math;

import 'package:atelier/logic/house.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/house_3d.dart';
import 'package:atelier/ui/house_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

/// Point de l'écran qui correspond au centre d'une pièce, avec le même cadrage que le plan.
Offset roomCenter(WidgetTester pTester, Worksite pWorksite, int pIndex) {
  final vCanvas = pTester.getRect(find.byKey(const ValueKey('house-plan')));
  final vPoints = [for (final vRoom in houseRooms(pWorksite)) ...houseOutline(vRoom)];
  final vMinX = vPoints.map((pPoint) => pPoint.x).reduce(math.min) - 1000;
  final vMinY = vPoints.map((pPoint) => pPoint.y).reduce(math.min) - 1000;
  final vMaxX = vPoints.map((pPoint) => pPoint.x).reduce(math.max) + 1000;
  final vMaxY = vPoints.map((pPoint) => pPoint.y).reduce(math.max) + 1000;
  final vScale = math.min(vCanvas.width / (vMaxX - vMinX), vCanvas.height / (vMaxY - vMinY));
  final vRoom = houseOutline(pWorksite.rooms[pIndex]);
  final vX = vRoom.map((pPoint) => pPoint.x).reduce((pA, pB) => pA + pB) / vRoom.length;
  final vY = vRoom.map((pPoint) => pPoint.y).reduce((pA, pB) => pA + pB) / vRoom.length;

  return vCanvas.topLeft + Offset((vX - vMinX) * vScale, vCanvas.height - (vY - vMinY) * vScale);
}

void main() {
  testWidgets('les pièces se rangent, se choisissent, se tournent et se déplacent', (
    pTester,
  ) async {
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom(), lShapedRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(HouseScreen(controller: vController, worksiteId: 'w')));

    await pTester.tap(find.byTooltip('Ranger les pièces pas encore placées'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms[1].houseXMm, 4500);

    await pTester.tapAt(roomCenter(pTester, vStorage.saved.single, 0));
    await pTester.pump();
    await pTester.tap(find.text('Quart de tour'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.first.houseQuarterTurns, 1);

    final vBefore = vStorage.saved.single.rooms.first.houseXMm;
    await pTester.dragFrom(roomCenter(pTester, vStorage.saved.single, 0), const Offset(60, 0));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.first.houseXMm, greaterThan(vBefore));
    expect(vStorage.saved.single.rooms.first.houseXMm % 50, 0);
  });

  testWidgets('la vue 3D s\'affiche et tourne au doigt', (pTester) async {
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(HouseScreen(controller: vController, worksiteId: 'w')));

    await pTester.tap(find.byTooltip('Vue en 3D'));
    await pTester.pump();
    expect(find.byType(House3d), findsOneWidget);
    await pTester.drag(find.byType(House3d), const Offset(120, 0));
    await pTester.pump();
    await pTester.tap(find.byTooltip('Plan à plat'));
    await pTester.pump();
    expect(find.byType(House3d), findsNothing);
  });
}
