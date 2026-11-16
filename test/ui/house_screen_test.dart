import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/house_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('les pièces se rangent, se choisissent, se tournent et se déplacent', (pTester) async {
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

    await pTester.tap(find.text('Salon'));
    await pTester.pump();
    await pTester.tap(find.text('Quart de tour'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.first.houseQuarterTurns, 1);

    final vBefore = vStorage.saved.single.rooms.first.houseXMm;
    await pTester.drag(find.text('Salon'), const Offset(60, 0));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.first.houseXMm, greaterThan(vBefore));
    expect(vStorage.saved.single.rooms.first.houseXMm % 50, 0);
  });
}
