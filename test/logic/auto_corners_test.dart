import 'package:atelier/logic/auto_corners.dart';
import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

Room _room(List<Wall> pWalls) => Room(id: 'r', name: 'Pièce', walls: pWalls);

void main() {
  const vMeasured = [3089, 4225, 2831, 4163];

  test('quatre murs mesurés au mètre : les angles se déduisent et le contour se referme', () {
    final vWalls = withFittedCorners([for (final vLength in vMeasured) Wall(lengthMm: vLength)]);

    expect(closesProperly(_room(vWalls)), isTrue);
    for (final vWall in vWalls) {
      expect(vWall.angleToNextDeg, inInclusiveRange(85, 95));
    }
    expect(vWalls.map((pWall) => pWall.angleToNextDeg).reduce((a, b) => a + b), closeTo(360, 0.01));
  });

  test('un vrai rectangle reste à 90 degrés', () {
    final vWalls = [for (final vLength in [4000, 3000, 4000, 3000]) Wall(lengthMm: vLength)];

    expect(withFittedCorners(vWalls), same(vWalls));
  });

  test('un angle saisi à la main n\'est jamais écrasé', () {
    final vWalls = [
      const Wall(lengthMm: 3089, angleToNextDeg: 80),
      for (final vLength in vMeasured.skip(1)) Wall(lengthMm: vLength),
    ];

    expect(withFittedCorners(vWalls), same(vWalls));
  });

  test('pas quatre murs, ou longueurs impossibles : rien n\'est ajusté', () {
    final vThree = [for (final vLength in [3000, 4000, 5000]) Wall(lengthMm: vLength)];
    final vImpossible = [for (final vLength in [1000, 1000, 1000, 5000]) Wall(lengthMm: vLength)];

    expect(withFittedCorners(vThree), same(vThree));
    expect(withFittedCorners(vImpossible), same(vImpossible));
    expect(bestFitCorners([1000, 1000, 1000, 5000]), isNull);
    expect(bestFitCorners([1, 2, 3]), isNull);
    expect(bestFitCorners([1000, 0, 1000, 1000]), isNull);
  });
}
