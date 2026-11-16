import 'dart:math' as math;

import 'package:atelier/logic/angle_measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repères à 50 cm et 70,7 cm d\'écart : coin droit', () {
    expect(cornerAngle(pSideAMm: 500, pSideBMm: 500, pDiagonalMm: 707), 90);
  });

  test('un écart plus court donne un coin fermé, arrondi au demi-degré', () {
    // 50 cm de chaque côté, 88° : écart de 2 × 500 × sin(44°) = 694,6 mm
    final vGap = (2 * 500 * math.sin(44 * math.pi / 180)).round();

    expect(cornerAngle(pSideAMm: 500, pSideBMm: 500, pDiagonalMm: vGap), 88);
    expect(cornerAngle(pSideAMm: 500, pSideBMm: 500, pDiagonalMm: 697), 88.5);
  });

  test('coin sortant : l\'angle de la pièce est le complément à 360°', () {
    expect(cornerAngle(pSideAMm: 500, pSideBMm: 500, pDiagonalMm: 707, pOutside: true), 270);
  });

  test('des repères à des distances différentes marchent aussi', () {
    // 3-4-5 : coin droit
    expect(cornerAngle(pSideAMm: 300, pSideBMm: 400, pDiagonalMm: 500), 90);
  });

  test('des mesures qui ne forment pas un triangle sont refusées', () {
    expect(cornerAngle(pSideAMm: 500, pSideBMm: 500, pDiagonalMm: 1000), isNull);
    expect(cornerAngle(pSideAMm: 500, pSideBMm: 200, pDiagonalMm: 300), isNull);
    expect(cornerAngle(pSideAMm: 0, pSideBMm: 500, pDiagonalMm: 400), isNull);
  });
}
