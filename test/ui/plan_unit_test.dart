import 'package:atelier/logic/units.dart';
import 'package:atelier/ui/plan_unit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget reader(List<FieldUnit> pSeen) => Builder(
    builder: (pContext) {
      pSeen.add(PlanUnit.of(pContext));

      return const SizedBox();
    },
  );

  testWidgets('sans réglage au-dessus, le plan est coté en centimètres', (pTester) async {
    final vSeen = <FieldUnit>[];

    await pTester.pumpWidget(reader(vSeen));

    expect(vSeen.single, FieldUnit.cm);
  });

  testWidgets('l\'unité choisie descend aux plans et change avec le réglage', (pTester) async {
    final vSeen = <FieldUnit>[];
    final vChild = reader(vSeen);

    await pTester.pumpWidget(PlanUnit(unit: FieldUnit.mm, child: vChild));
    // Même unité : les plans ne sont pas redessinés pour rien
    await pTester.pumpWidget(PlanUnit(unit: FieldUnit.mm, child: vChild));
    await pTester.pumpWidget(PlanUnit(unit: FieldUnit.m, child: vChild));

    expect(vSeen, [FieldUnit.mm, FieldUnit.m]);
  });
}
