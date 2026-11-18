import 'package:atelier/logic/reverberation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grand volume vide de 8 × 6 × 5 m : près de 4 s, il faut beaucoup de panneaux', () {
    final vPlan = planReverb(
      pLengthMm: 8000,
      pWidthMm: 6000,
      pHeightMm: 5000,
      pFloor: SoundFloor.parquet,
      pCeiling: SoundCeiling.plaster,
      pFurnished: false,
    );
    expect(vPlan.volumeM3, closeTo(240, 1e-9));
    expect(vPlan.absorptionM2, closeTo(9.96, 1e-9));
    expect(vPlan.seconds, closeTo(3.88, 0.01));
    expect(vPlan.panels, 87);
  });

  test('meublé, plafond acoustique : quelques panneaux sur parquet, aucun sur moquette', () {
    final vParquet = planReverb(
      pLengthMm: 8000,
      pWidthMm: 6000,
      pHeightMm: 5000,
      pFloor: SoundFloor.parquet,
      pCeiling: SoundCeiling.acoustic,
    );
    expect(vParquet.seconds, closeTo(0.64, 0.01));
    expect(vParquet.panels, 7);

    final vCarpet = planReverb(
      pLengthMm: 8000,
      pWidthMm: 6000,
      pHeightMm: 5000,
      pFloor: SoundFloor.carpet,
      pCeiling: SoundCeiling.acoustic,
    );
    expect(vCarpet.seconds, closeTo(0.54, 0.01));
    expect(vCarpet.panels, 0);
  });

  test('séjour ordinaire meublé', () {
    final vPlan = planReverb(
      pLengthMm: 5000,
      pWidthMm: 4000,
      pHeightMm: 2500,
      pFloor: SoundFloor.parquet,
      pCeiling: SoundCeiling.plaster,
    );
    expect(vPlan.seconds, closeTo(0.685, 0.01));
    expect(vPlan.panels, 3);
  });

  test('pièce vide de dimensions nulles : pas de division par zéro', () {
    final vPlan = planReverb(
      pLengthMm: 0,
      pWidthMm: 0,
      pHeightMm: 0,
      pFloor: SoundFloor.tiles,
      pCeiling: SoundCeiling.wood,
    );
    expect(vPlan.seconds, 0);
    expect(vPlan.panels, 0);
  });
}
