import 'package:atelier/logic/roof_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chevrons à 60 cm : même la plus étroite demande un chevêtre', () {
    final vFit = fitRoofWindow(
      pSpacingMm: 600,
      pRafterWidthMm: 63,
      pWantedWidthMm: 500,
      pSlopeDeg: 40,
    );

    expect(vFit.clearWidthMm, 537);
    expect(vFit.widestWithoutCutMm, isNull);
    expect(vFit.chosenWidthMm, 550);
    expect(vFit.needsHeader, isTrue);
    expect(vFit.heightMm, 1180);
  });

  test('chevrons à 90 cm : 78 cm sans chevêtre', () {
    final vFit = fitRoofWindow(
      pSpacingMm: 900,
      pRafterWidthMm: 45,
      pWantedWidthMm: 700,
      pSlopeDeg: 50,
    );

    expect(vFit.widestWithoutCutMm, 780);
    expect(vFit.chosenWidthMm, 780);
    expect(vFit.needsHeader, isFalse);
    expect(vFit.heightMm, 980);
  });

  test('trop large même avec un chevron coupé : aucune fenêtre', () {
    final vFit = fitRoofWindow(
      pSpacingMm: 500,
      pRafterWidthMm: 75,
      pWantedWidthMm: 1300,
      pSlopeDeg: 25,
    );

    expect(vFit.chosenWidthMm, isNull);
    expect(vFit.needsHeader, isFalse);
    expect(vFit.heightMm, 1400);
  });
}
