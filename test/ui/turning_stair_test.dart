import 'package:atelier/ui/stair_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('escalier : la forme change l\'emprise au sol', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const StairCalculator()));

    expect(find.text('Emprise au sol : 420 × 80 cm'), findsOneWidget);
    expect(find.textContaining('marches balancées'), findsNothing);

    await pTester.tap(find.text('Quart tournant'));
    await pTester.pump();
    expect(find.text('Emprise au sol : 248 × 276 cm'), findsOneWidget);
    expect(find.text('2 marches dans le tournant, 6 marches balancées en tout'), findsOneWidget);
  });
}
