import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/worksite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('objectif proposé, suivi, puis badges', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [
            rectangleRoom().copyWith(
              laidRows: const [1],
              touchUps: const [TouchUp(id: 'a', label: 'Enduit', passes: 2)],
            ),
            const Room(id: 'z', name: 'Toit'),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        WorksiteScreen(controller: vController, worksiteId: 'w', today: DateTime(2026, 11, 16)),
      ),
    );

    expect(find.text('Objectif du jour'), findsOneWidget);
    await pTester.tap(find.text('Me proposer un objectif'));
    await pTester.pumpAndSettle();

    expect(find.text('Salon : poser les rangées 2 à 6'), findsOneWidget);
    expect(find.text('Salon : Enduit, jusqu\'au passage 1'), findsOneWidget);
    expect(find.text('0 sur 2'), findsOneWidget);
    expect(vStorage.saved.single.goal!.date, '2026-11-16');

    await vController.updateRoom(
      'w',
      vController
          .worksite('w')!
          .rooms
          .first
          .copyWith(
            laidRows: const [1, 2, 3, 4, 5, 6],
            touchUps: const [TouchUp(id: 'a', label: 'Enduit', passes: 2, donePasses: 1)],
          ),
    );
    await pTester.pumpAndSettle();
    expect(find.text('Objectif atteint pour aujourd\'hui.'), findsOneWidget);

    await pTester.tap(find.byTooltip('Badges'));
    await pTester.pumpAndSettle();
    expect(find.text('2 badges sur 7'), findsOneWidget);
  });
}
