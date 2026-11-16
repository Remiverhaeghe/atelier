import 'package:atelier/logic/heating.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/heating_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('chauffage : puissance par pièce, isolation changée', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(
            id: 'w',
            name: 'Maison',
            rooms: [
              rectangleRoom(),
              rectangleRoom().copyWith(name: 'Garage', usage: RoomUsage.garage),
            ],
          ),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(HeatingScreen(controller: vController, worksiteId: 'w')));

    expect(find.text('Salon : 1092 W'), findsOneWidget);
    expect(find.textContaining('Garage'), findsNothing);
    expect(find.text('1 radiateur de 1250 W'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<InsulationLevel>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Peu ou pas isolée (C = 1,8)').last);
    await pTester.pumpAndSettle();
    expect(find.text('Salon : 1404 W'), findsOneWidget);
  });
}
