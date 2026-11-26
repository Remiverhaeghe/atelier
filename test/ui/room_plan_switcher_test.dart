import 'package:atelier/ui/room_plan.dart';
import 'package:atelier/ui/room_plan_switcher.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('le plan s\'ouvre en Simple, et Complet rend le détail', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(RoomPlanSwitcher(room: rectangleRoom())));

    expect(pTester.widget<RoomPlan>(find.byType(RoomPlan)).simple, isTrue);

    await pTester.tap(find.text('Complet'));
    await pTester.pump();
    expect(pTester.widget<RoomPlan>(find.byType(RoomPlan)).simple, isFalse);

    await pTester.tap(find.text('Simple'));
    await pTester.pump();
    expect(pTester.widget<RoomPlan>(find.byType(RoomPlan)).simple, isTrue);
  });
}
