import 'package:atelier/logic/exterior.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('façade avec pignon, ouvertures déduites', () {
    const vFacade = (widthMm: 8000, heightMm: 5500, gableMm: 3000, openingsM2: 8.0);
    expect(facadeM2(vFacade), closeTo(44 + 12 - 8, 1e-9));
    expect(facadePaintLitres(48), 16);
    expect(renderBags(48), 33);
    expect(facadeM2((widthMm: 1000, heightMm: 1000, gableMm: 0, openingsM2: 5)), 0);
  });

  test('clôture : panneaux, poteaux, béton et dernier panneau recoupé', () {
    final vPlan = fencePlan(23400, pSides: 3);
    expect(vPlan.panels, 10);
    expect(vPlan.posts, 13);
    expect(vPlan.concreteBags, 35);
    expect(vPlan.lastPanelMm, 900);
    expect(fencePlan(5000).posts, 3);
    expect(fencePlan(5000, pSides: 0).posts, 3);
    expect(fencePlan(0).panels, 0);
  });
}
