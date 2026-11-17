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

  testWidgets('escalier : garde-corps selon les côtés dans le vide', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const StairCalculator()));

    expect(find.textContaining('6 poteaux et 34 barreaux'), findsOneWidget);
    await pTester.tap(find.text('Entre deux murs'));
    await pTester.pump();
    expect(find.textContaining('barreaux'), findsNothing);
    expect(find.textContaining('504,8 cm de main courante'), findsOneWidget);
  });
}
