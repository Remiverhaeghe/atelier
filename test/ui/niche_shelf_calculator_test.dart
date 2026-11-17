import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('niche puis rampant : tablettes et montants suivent la saisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Étagère en niche ou sous rampant');
    await pTester.tap(find.text('Étagère en niche ou sous rampant'));
    await pTester.pumpAndSettle();

    expect(find.text('4 tablettes de 79,6 cm'), findsOneWidget);
    expect(find.text('44 vis et chevilles, une tous les 25 cm'), findsOneWidget);

    await pTester.tap(find.text('Sous un rampant'));
    await pTester.pump();
    expect(
      find.text('Montants de 80 cm côté mur et 110 cm côté pièce, haut coupé à 45°'),
      findsOneWidget,
    );
    expect(find.text('Tablette à 100 cm du sol : 10 cm de profondeur'), findsOneWidget);
  });
}
