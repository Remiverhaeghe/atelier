import 'package:atelier/logic/bar_cutting.dart';
import 'package:atelier/logic/baseboard.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('les plus longs d\'abord, chacun dans la première barre où il tient', () {
    final vPlan = planBars([2000, 1500, 1500, 800, 400, 300], 2400, 2);

    expect(vPlan.bars, hasLength(3));
    expect(vPlan.bars[0].pieceLengths, [2000, 300]);
    expect(vPlan.bars[1].pieceLengths, [1500, 800]);
    expect(vPlan.bars[2].pieceLengths, [1500, 400]);
    expect(vPlan.bars.map((pBar) => pBar.offcutMm(2)), [96, 96, 496]);
    expect(vPlan.reusableOffcuts, [496]);
    expect(vPlan.barOf(4), 3);
    expect(vPlan.barOf(5), 1);
    expect(vPlan.barOf(99), isNull);
  });

  test('le trait de scie empêche deux moitiés exactes de tenir dans une barre', () {
    expect(planBars([1200, 1200], 2400, 2).bars, hasLength(2));

    final vNoKerf = planBars([1200, 1200], 2400, 0);
    expect(vNoKerf.bars, hasLength(1));
    expect(vNoKerf.bars.single.offcutMm(0), 0);
  });

  test('une barre entière pour un morceau de sa longueur, sans chute', () {
    final vPlan = planBars([2400], 2400, 2);

    expect(vPlan.bars.single.offcutMm(2), 0);
    expect(vPlan.reusableOffcuts, isEmpty);
  });

  test('un morceau plus long qu\'une barre est signalé, pas placé', () {
    final vPlan = planBars([2500, 1000, 0], 2400, 2);

    expect(vPlan.tooLong, [0]);
    expect(vPlan.bars, hasLength(1));
  });

  test('pièce rectangulaire : huit barres, une chute de 39,8 cm par morceau de 2 m', () {
    final vPieces = baseboardPieces(rectangleRoom(), const BaseboardSettings());
    final vPlan = planBars([for (final vPiece in vPieces) vPiece.lengthMm], 2400, 2);

    expect(vPlan.bars, hasLength(8));
    expect(vPlan.reusableOffcuts, [398, 398, 398, 398, 898, 898, 898, 898]);
  });

  test('sans morceau, aucune barre', () {
    expect(planBars(const [], 2400, 2).bars, isEmpty);
  });
}
