import 'package:atelier/ui/starter_tools_screen.dart';
import 'package:atelier/ui/trades_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('les prix proposés par l\'appli sont présentés comme une estimation', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const StarterToolsScreen()));
    await scrollToFirst(pTester, find.textContaining("Estimation : fourchettes de prix"));
    expect(find.textContaining('fixées dans l\'appli en 2026'), findsOneWidget);

    await pTester.pumpWidget(localized(const TradesScreen()));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Estimation : fourchettes de prix'), findsOneWidget);
  });
}
