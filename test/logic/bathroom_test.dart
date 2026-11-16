import 'package:atelier/logic/bathroom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('douche dans une alcôve, évacuation au centre', () {
    final vPlan = showerPlan((
      widthMm: 1200,
      depthMm: 900,
      drain: DrainKind.centre,
      siphonMm: 80,
      pipeMm: 2500,
      walls: 3,
    ));
    expect(vPlan.runMm, 600);
    expect(vPlan.riseMm, 12);
    // 80 mm de siphon et 25 mm de pente sur 2,50 m de tuyau
    expect(vPlan.drainLevelMm, 105);
    expect(vPlan.edgeLevelMm, 117);
    expect(vPlan.specFloorM2, closeTo(1.08, 1e-9));
    expect(vPlan.specWallM2, closeTo(6, 1e-9));
    // 3 m au pied des murs, 2 angles verticaux de 2 m
    expect(vPlan.cornerBandM, closeTo(7, 1e-9));
  });

  test('caniveau le long du mur : une seule pente sur toute la profondeur', () {
    const vShower = (
      widthMm: 900,
      depthMm: 1400,
      drain: DrainKind.channel,
      siphonMm: 60,
      pipeMm: 0,
      walls: 1,
    );
    final vPlan = showerPlan(vShower);
    expect(vPlan.runMm, 1400);
    expect(vPlan.riseMm, 28);
    expect(vPlan.cornerBandM, closeTo(0.9, 1e-9));
    expect(showerWallsMm(vShower), 900);
  });

  test('murs comptés de zéro à trois', () {
    Shower vWith(int pWalls) => (
      widthMm: 1000,
      depthMm: 800,
      drain: DrainKind.centre,
      siphonMm: 70,
      pipeMm: 1000,
      walls: pWalls,
    );
    expect([for (final vWalls in [0, 2, 5]) showerWallsMm(vWith(vWalls))], [0, 1800, 2600]);
    expect(showerPlan(vWith(0)).cornerBandM, 0);
    expect(showerPlan(vWith(2)).cornerBandM, closeTo(3.8, 1e-9));
  });
}
