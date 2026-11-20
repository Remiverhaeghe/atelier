import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/elec_plan_screen.dart';
import 'package:atelier/ui/room_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('prises et éclairage : minimum de la pièce, puis posés sur le plan', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(
            id: 'w',
            name: 'Maison',
            rooms: [
              rectangleRoom().copyWith(
                fixtures: const [
                  Fixture(id: 'a', kind: FixtureKind.socket, xMm: 1400, yMm: 0, count: 2),
                ],
              ),
            ],
          ),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(ElecPlanScreen(controller: vController, worksiteId: 'w')));
    expect(find.text('2 prises posées sur 5 au minimum : toucher pour placer'), findsOneWidget);

    await pTester.tap(find.text('Salon'));
    await pTester.pumpAndSettle();
    expect(find.text('Prises et éclairage : Salon'), findsOneWidget);
    expect(find.byType(RoomPlan), findsOneWidget);
    expect(find.text('5 prises au minimum'), findsOneWidget);
    expect(find.text('2 déjà posées sur le plan, 3 à ajouter'), findsOneWidget);
    expect(find.text('Un interrupteur à côté de la porte, côté mur libre'), findsOneWidget);

    await pTester.tap(find.text('Poser sur le plan'));
    await pTester.pumpAndSettle();
    final vRoom = vController.worksite('w')!.rooms.single;
    expect(vRoom.fixtures, hasLength(5));
    expect(find.text('Le minimum est déjà posé'), findsOneWidget);
    expect(find.text('Interrupteur déjà posé sur le plan'), findsOneWidget);

    // Une chambre demande moins de prises
    await pTester.tap(find.text('Séjour'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Chambre').last);
    await pTester.pumpAndSettle();
    expect(find.text('3 prises au minimum'), findsOneWidget);

    pTester.state<NavigatorState>(find.byType(Navigator)).pop();
    await pTester.pumpAndSettle();
    expect(find.text('5 prises posées sur 5 au minimum : toucher pour placer'), findsOneWidget);
  });

  testWidgets('salle d’eau : les volumes de sécurité sont rappelés', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(
            id: 'w',
            name: 'Maison',
            rooms: [rectangleRoom().copyWith(name: "Salle d'eau")],
          ),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(ElecPlanScreen(controller: vController, worksiteId: 'w')));
    await pTester.tap(find.text("Salle d'eau"));
    await pTester.pumpAndSettle();
    expect(find.textContaining('hors des volumes 0, 1 et 2'), findsOneWidget);
    expect(find.text('1 prise au minimum'), findsOneWidget);
  });
}
