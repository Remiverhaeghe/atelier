import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/elec_plan_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('électricité du plan : vide, puis circuits d\'après les prises', (pTester) async {
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
                  Fixture(id: 'a', kind: FixtureKind.socket, xMm: 0, yMm: 0, count: 2),
                  Fixture(id: 'i', kind: FixtureKind.lightSwitch, xMm: 500, yMm: 0),
                ],
              ),
            ],
          ),
          const Worksite(id: 'v', name: 'Vide'),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(ElecPlanScreen(controller: vController, worksiteId: 'w')));
    expect(find.text('2 circuits'), findsOneWidget);
    expect(find.text('3 boîtes d\'encastrement'), findsOneWidget);

    await pTester.pumpWidget(localized(ElecPlanScreen(controller: vController, worksiteId: 'v')));
    expect(find.textContaining('Posez les prises'), findsOneWidget);
  });
}
