import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('pergola : les chevrons suivent la couverture et la neige', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Pergola ou auvent');
    await pTester.tap(find.text('Pergola ou auvent'));
    await pTester.pumpAndSettle();

    expect(find.text('8 chevrons de 45 × 145 mm en C24, tous les 60 cm'), findsOneWidget);
    expect(find.textContaining('160 litres de béton'), findsOneWidget);
    expect(
      find.text('Neige sur la couverture : 36 kg/m², poids propre : 25 kg/m²'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Adossée à la façade'));
    await pTester.pump();
    expect(find.textContaining('320 litres de béton'), findsOneWidget);
  });
}
