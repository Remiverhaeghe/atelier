import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/living_area_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('surface habitable par niveau, usage changé en garage', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [
            rectangleRoom(),
            const Room(
              id: 'g',
              name: 'Garage',
              walls: [
                Wall(lengthMm: 3000),
                Wall(lengthMm: 3000),
                Wall(lengthMm: 3000),
                Wall(lengthMm: 3000),
              ],
            ),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(LivingAreaScreen(controller: vController, worksiteId: 'w')));

    expect(find.text('21,00 m²'), findsOneWidget);

    await pTester.tap(find.text('Habitable').last);
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Garage, remise').last);
    await pTester.pumpAndSettle();

    expect(vStorage.saved.single.rooms.last.usage, RoomUsage.garage);
    expect(find.text('12,00 m²'), findsOneWidget);
    expect(find.text('Loi Carrez : 12,00 m²'), findsOneWidget);
  });
}
