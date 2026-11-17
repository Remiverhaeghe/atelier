import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/visit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('visite : un point coché avec sa note devient une reprise', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage, pNewId: () => 'v');
    await vController.load();
    await pTester.pumpWidget(
      localized(
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => VisitScreen(controller: vController, worksiteId: 'w'),
          ),
        ),
      ),
    );
    expect(find.text('Rien à voir'), findsOneWidget);

    await pTester.tap(find.text('Salon'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Fissures aux angles des portes et fenêtres'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), 'Au-dessus de la porte');
    await pTester.pump();
    expect(find.text('Ajouter 1 point aux reprises'), findsOneWidget);

    await pTester.tap(find.text('Ajouter 1 point aux reprises'));
    await pTester.pumpAndSettle();
    final vTouchUp = vStorage.saved.single.rooms.single.touchUps.single;
    expect(vTouchUp.label, 'Fissures aux angles des portes et fenêtres');
    expect(vTouchUp.note, 'Au-dessus de la porte');
  });
}
