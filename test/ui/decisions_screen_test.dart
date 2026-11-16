import 'package:atelier/ui/decisions_screen.dart';
import 'package:atelier/ui/tips_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('les façons de faire se comparent depuis les conseils', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const TipsScreen()));
    await pTester.tap(find.text('Aide à la décision').first);
    await pTester.pumpAndSettle();

    expect(find.byType(DecisionsScreen), findsOneWidget);
    expect(find.text('Plinthes : coller, clouer ou clipser ?'), findsOneWidget);
    expect(find.text('Le plus simple'), findsWidgets);
  });
}
