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

  test('référence de fenêtre de toit : code actuel, avec modèle, ancien code', () {
    expect(roofWindowFromReference('MK08'), (widthMm: 780, heightMm: 1400, code: 'M08'));
    expect(roofWindowFromReference('ggl ck04'), (widthMm: 550, heightMm: 980, code: 'C04'));
    expect(roofWindowFromReference('GGU-UK10'), (widthMm: 1340, heightMm: 1600, code: 'U10'));
    expect(roofWindowFromReference('S06'), (widthMm: 1140, heightMm: 1180, code: 'S06'));
    // Anciennes références : le premier chiffre donne la largeur
    expect(roofWindowFromReference('308'), (widthMm: 780, heightMm: 1400, code: 'M08'));
    expect(roofWindowFromReference('GGL 606'), (widthMm: 1140, heightMm: 1180, code: 'S06'));
    expect(roofWindowFromReference('804'), (widthMm: 1340, heightMm: 980, code: 'U04'));
  });

  test('référence inconnue', () {
    expect(roofWindowFromReference('XK04'), isNull);
    expect(roofWindowFromReference('MK07'), isNull);
    expect(roofWindowFromReference('508'), isNull);
    expect(roofWindowFromReference(''), isNull);
  });

  test('code de taille à donner pour un store : celui de la plaque', () {
    expect(roofWindowSizeCode('GGL MK08'), 'MK08');
    expect(roofWindowSizeCode('ck04'), 'CK04');
    expect(roofWindowSizeCode('S06'), 'S06');
    expect(roofWindowSizeCode('GGL 308'), '308');
    expect(roofWindowSizeCode('ZZ99'), isNull);
  });
}
