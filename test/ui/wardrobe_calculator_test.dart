import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('armoire : compartiments ajoutés ou changés, débit à jour', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Armoire sur mesure');
    await pTester.tap(find.text('Armoire sur mesure'));
    await pTester.pumpAndSettle();

    expect(find.text('1 × tringle de 57,3 cm'), findsOneWidget);
    expect(find.text('10 charnières, selon la hauteur des portes'), findsOneWidget);

    await pTester.tap(find.text('Ajouter un compartiment'));
    await pTester.pump();
    expect(find.text('2 × séparation de 216,4 cm × 60 cm'), findsOneWidget);

    await pTester.tap(find.text('Penderie').last);
    await pTester.pump();
    expect(find.text('2 × tringle de 37,6 cm'), findsOneWidget);
  });
}
