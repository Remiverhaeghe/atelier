import 'package:atelier/logic/window_sealing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('châssis de 79 × 99 cm, 5 mm de jeu, vitrage de 70,2 × 90,2 cm', () {
    final vSealing = planWindowSealing(
      pFrameWidthMm: 790,
      pFrameHeightMm: 990,
      pGapMm: 5,
      pGlassWidthMm: 702,
      pGlassHeightMm: 902,
    );
    // Vitrage mastiqué dedans et dehors : 4 × (702 + 902) mm
    expect(vSealing.glazingSealantM, 7);
    expect(vSealing.glazingCartridges, 1);
    expect(vSealing.outsideSealantM, 4);
    expect(vSealing.outsideCartridges, 2);
    // Trois côtés de mousse : 3560 − 790 mm
    expect(vSealing.foamM, 3);
    expect(vSealing.foamRolls, 1);
    expect(vSealing.foam, (2, 6));
    expect(vSealing.vapourTapeM, 4);
    expect(vSealing.vapourTapeRolls, 1);
  });

  test('jeu trop large pour une mousse : rien ne convient', () {
    final vSealing = planWindowSealing(
      pFrameWidthMm: 790,
      pFrameHeightMm: 990,
      pGapMm: 25,
      pGlassWidthMm: 702,
      pGlassHeightMm: 902,
    );
    expect(vSealing.foam, isNull);
  });

  test('un jeu de 8 mm prend la mousse 5-9', () {
    final vSealing = planWindowSealing(
      pFrameWidthMm: 600,
      pFrameHeightMm: 600,
      pGapMm: 8,
      pGlassWidthMm: 500,
      pGlassHeightMm: 500,
    );
    expect(vSealing.foam, (5, 9));
  });
}
