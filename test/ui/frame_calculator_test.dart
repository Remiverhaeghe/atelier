import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/window_frame.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/plexi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('plexis listés, puis cadre calculé pour leur taille', (pTester) async {
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
                  Fixture(
                    id: 'v',
                    kind: FixtureKind.roofWindow,
                    xMm: 1000,
                    yMm: 1000,
                    widthMm: 780,
                    depthMm: 980,
                    plexi: true,
                  ),
                ],
              ),
            ],
          ),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(PlexiScreen(controller: vController, worksiteId: 'w')));

    expect(find.text('0,76 m²'), findsOneWidget);
    expect(find.text('Fenêtre de toit courante la plus proche : 78 × 98 cm'), findsOneWidget);
    expect(find.text('chevêtre à élargir de 2 cm, à allonger de 2 cm'), findsOneWidget);
    await pTester.tap(find.text('1 × 78 × 98 cm'));
    await pTester.pumpAndSettle();

    expect(find.text('2 montants de 97 cm'), findsOneWidget);
    expect(find.text('71 × 91 cm'), findsOneWidget);

    await pTester.tap(find.byType(DropdownButtonFormField<Glazing>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Plexi neuf').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Section du bois : 4,5 × 4 cm'), findsOneWidget);

    await pTester.enterText(find.byType(TextField).first, '10');
    await pTester.pumpAndSettle();
    expect(find.textContaining('trop petite'), findsOneWidget);
  });

  testWidgets('sans plexi, l\'écran explique comment en marquer un', (pTester) async {
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(localized(PlexiScreen(controller: vController, worksiteId: 'w')));

    expect(find.textContaining('Aucune fenêtre de toit en plexi'), findsOneWidget);
  });
}
