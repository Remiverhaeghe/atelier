/// Réverbération d'une pièce (formule de Sabine) : une grande pièce aux murs nus résonne,
/// la parole devient pénible. On compte l'absorption de chaque surface, à 500 Hz.
library;

import 'dart:math' as math;

/// Revêtement de sol et sa part de son absorbé.
enum SoundFloor {
  tiles(absorption: 0.02),
  parquet(absorption: 0.07),
  carpet(absorption: 0.3);

  const SoundFloor({required this.absorption});

  final double absorption;
}

/// Plafond et sa part de son absorbé.
enum SoundCeiling {
  plaster(absorption: 0.05),
  wood(absorption: 0.1),
  acoustic(absorption: 0.7);

  const SoundCeiling({required this.absorption});

  final double absorption;
}

/// Murs enduits ou en plaque de plâtre peinte.
const wallAbsorption = 0.03;

/// Canapé, rideaux, étagères garnies : absorption équivalente par mètre carré de sol.
const furnishedAbsorptionPerM2 = 0.4;

/// Panneau acoustique mural courant : 120 × 60 cm, absorbe 90 % du son.
const acousticPanelM2 = 0.72;
const acousticPanelAbsorption = 0.9;

/// Durée de réverbération confortable pour un séjour, en secondes.
const comfortableReverbSeconds = 0.6;

typedef ReverbPlan = ({double volumeM3, double absorptionM2, double seconds, int panels});

/// Pièce de [pLengthMm] × [pWidthMm] sous [pHeightMm], meublée si [pFurnished].
ReverbPlan planReverb({
  required int pLengthMm,
  required int pWidthMm,
  required int pHeightMm,
  required SoundFloor pFloor,
  required SoundCeiling pCeiling,
  bool pFurnished = true,
  double pTargetSeconds = comfortableReverbSeconds,
}) {
  final vFloorM2 = pLengthMm * pWidthMm / 1e6;
  final vWallsM2 = 2 * (pLengthMm + pWidthMm) * pHeightMm / 1e6;
  final vVolume = vFloorM2 * pHeightMm / 1000;
  final vAbsorption = math.max(
    1e-6,
    vFloorM2 * (pFloor.absorption + pCeiling.absorption) +
        vWallsM2 * wallAbsorption +
        (pFurnished ? vFloorM2 * furnishedAbsorptionPerM2 : 0),
  );
  final vSeconds = 0.161 * vVolume / vAbsorption;
  final vMissing = 0.161 * vVolume / pTargetSeconds - vAbsorption;
  // Un panneau remplace un morceau de mur nu
  final vPerPanel = acousticPanelM2 * (acousticPanelAbsorption - wallAbsorption);
  final rPlan = (
    volumeM3: vVolume,
    absorptionM2: vAbsorption,
    seconds: vSeconds,
    panels: vMissing <= 0 ? 0 : (vMissing / vPerPanel - 1e-9).ceil(),
  );

  return rPlan;
}
