import 'package:atelier/logic/units.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/plan_unit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('carrelage : coupes et cartons suivent le calepinage', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Carrelage et faïence');
    await pTester.tap(find.text('Carrelage et faïence'));
    await pTester.pumpAndSettle();

    expect(find.text('5 cartons'), findsOneWidget);
    expect(
      find.text('Longueur : 4 carreaux entiers, coupes de 29,2 cm et 29,3 cm'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Calepinage centré'));
    await pTester.pump();
    expect(find.text('Longueur : 4 carreaux entiers, une coupe de 58,8 cm'), findsOneWidget);
  });

  testWidgets('carrelage : les coupes s\'écrivent dans l\'unité choisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(const PlanUnit(unit: FieldUnit.mm, child: CalculatorsScreen())),
    );
    await scrollToTile(pTester, 'Carrelage et faïence');
    await pTester.tap(find.text('Carrelage et faïence'));
    await pTester.pumpAndSettle();

    expect(find.text('Longueur : 4 carreaux entiers, coupes de 292 mm et 293 mm'), findsOneWidget);
  });
}
