import 'package:atelier/logic/high_paint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matériel selon la hauteur : rouleau, manche, escabeau, échafaudage', () {
    expect(highAccess(2400), (access: HighAccess.roller, poleMm: null));
    expect(highAccess(3000), (access: HighAccess.telescopicPole, poleMm: 1000));
    expect(highAccess(4500), (access: HighAccess.poleAndStepladder, poleMm: 3000));
    expect(highAccess(6000), (access: HighAccess.scaffold, poleMm: 4000));
    expect(highAccess(7500), (access: HighAccess.scaffold, poleMm: null));
  });

  test('quantités mur et plafond, ouvertures déduites, en pots de 10 L', () {
    final vPlan = highPaintPlan(
      pPerimeterMm: 16000,
      pHeightMm: 5000,
      pCeilingM2: 16,
      pOpeningsM2: 6,
    );
    expect(vPlan.wallM2, closeTo(74, 1e-9));
    expect(vPlan.wallLitres, closeTo(14.8, 1e-9));
    expect(vPlan.wallCans, 2);
    expect(vPlan.ceilingLitres, closeTo(3.2, 1e-9));
    expect(vPlan.ceilingCans, 1);
    final vEmpty = highPaintPlan(
      pPerimeterMm: 1000,
      pHeightMm: 1000,
      pCeilingM2: 0,
      pOpeningsM2: 5,
      pCoverageM2PerL: 0,
    );
    expect(vEmpty.wallM2, 0);
    expect(vEmpty.wallCans, 0);
  });

  test('ordre sans reprise : on déplace l\'échafaudage, on ne coupe pas le mur en deux', () {
    final vScaffold = highPaintSteps(HighAccess.scaffold);
    expect(vScaffold.first, HighPaintStep.protect);
    expect(
      vScaffold.indexOf(HighPaintStep.ceilingFirst),
      lessThan(vScaffold.indexOf(HighPaintStep.verticalBands)),
    );
    expect(vScaffold, contains(HighPaintStep.moveAlong));
    expect(highPaintSteps(HighAccess.telescopicPole), isNot(contains(HighPaintStep.moveAlong)));
  });
}
