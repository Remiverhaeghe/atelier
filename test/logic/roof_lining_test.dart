import 'package:atelier/logic/roof_lining.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rampant à 45°, 20 cm d\'épaisseur : haut et bas de même longueur', () {
    final vLining = planRoofLining(
      pWindowWidthMm: 780,
      pWindowHeightMm: 980,
      pDepthMm: 200,
      pSlopeDeg: 45,
    );
    expect(vLining.topMm, 283);
    expect(vLining.bottomMm, 283);
    // 980 + 200 × (1 + 1)
    expect(vLining.ceilingOpeningMm, 1380);
    expect(vLining.gainMm, 400);
    expect(vLining.boardM2, closeTo(0.913, 0.001));
  });

  test('rampant à 30° : haut plus long, bas plus court', () {
    final vLining = planRoofLining(
      pWindowWidthMm: 780,
      pWindowHeightMm: 980,
      pDepthMm: 200,
      pSlopeDeg: 30,
    );
    expect(vLining.topMm, 400);
    expect(vLining.bottomMm, 231);
    expect(vLining.ceilingOpeningMm, 1442);
  });

  test('sans épaisseur, pas d\'embrasure', () {
    final vLining = planRoofLining(
      pWindowWidthMm: 780,
      pWindowHeightMm: 980,
      pDepthMm: 0,
      pSlopeDeg: 40,
    );
    expect(vLining.topMm, 0);
    expect(vLining.ceilingOpeningMm, 980);
    expect(vLining.boardM2, 0);
  });
}
