import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/planning_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('planning : parquet posé avant les murs, l\'inversion est signalée', (pTester) async {
    final vRoom = rectangleRoom().copyWith(
      paint: const PaintSettings(walls: true),
      laidRows: [for (var vRow = 1; vRow <= 40; vRow++) vRow],
    );
    await pTester.pumpWidget(
      localized(PlanningCard(worksite: Worksite(id: 'w', name: 'Maison', rooms: [vRoom]))),
    );
    expect(find.textContaining('Salon : « poser le parquet » est fait'), findsOneWidget);
  });
}
