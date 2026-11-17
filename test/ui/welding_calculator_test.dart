import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('soudure : le procédé conseillé suit le métal et le lieu', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    // La grille des calculs s'allonge à chaque nouveau calcul : défiler jusqu'à la tuile
    await scrollToTile(pTester, 'Soudure');
    await pTester.tap(find.text('Soudure'));
    await pTester.pumpAndSettle();

    expect(find.text('MIG/MAG, fil plein sous gaz'), findsOneWidget);
    expect(find.text('Électrode rutile de 2,5 mm'), findsOneWidget);

    await pTester.tap(find.text('Dehors, au vent'));
    await pTester.pump();
    final vStick = pTester.getTopLeft(find.text('Électrode enrobée (MMA)'));
    final vMig = pTester.getTopLeft(find.text('MIG/MAG, fil plein sous gaz'));
    expect(vStick.dy, lessThan(vMig.dy));

    await pTester.tap(find.text('Alu'));
    await pTester.pump();
    expect(find.text('Électrode enrobée (MMA)'), findsNothing);
    expect(find.textContaining('courant alternatif'), findsOneWidget);
  });
}
