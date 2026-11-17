/// Échafaudage roulant : hauteur du plancher, nombre d'éléments, stabilisateurs.
///
/// Règles de prédimensionnement courantes, la notice du fabricant reste la référence :
/// on travaille à 2 m au-dessus du plancher, le plancher se règle de 50 en 50 cm, le
/// garde-corps monte à 1 m au-dessus. Sans stabilisateurs, la hauteur ne dépasse pas
/// 3,5 fois la plus petite largeur à l'intérieur, 3 fois dehors à cause du vent.
library;

import 'dart:math' as math;

/// Hauteur qu'on atteint debout sur le plancher.
const towerReachMm = 2000;

/// Pas de réglage du plancher.
const towerStepMm = 500;

/// Hauteur d'un élément de cadre.
const towerFrameMm = 2000;

/// Garde-corps au-dessus du plancher.
const towerGuardrailMm = 1000;

/// Au-delà de ces hauteurs de plancher, on fait monter l'échafaudage par un professionnel.
const towerMaxIndoorMm = 12000;
const towerMaxOutdoorMm = 8000;

/// Largeur de la base.
enum TowerBase {
  narrow(widthMm: 750),
  wide(widthMm: 1350);

  const TowerBase({required this.widthMm});

  final int widthMm;
}

typedef TowerPlan = ({
  int platformMm,
  int frames,
  int totalHeightMm,
  bool needsStabilisers,
  bool tooHigh,
});

/// Échafaudage pour atteindre [pReachMm] (plafond, haut de mur), dehors si [pOutdoor].
TowerPlan planTower({required int pReachMm, required TowerBase pBase, bool pOutdoor = false}) {
  final vPlatform = math.max(0, ((pReachMm - towerReachMm) / towerStepMm).ceil() * towerStepMm);
  final vTotal = vPlatform + towerGuardrailMm;
  final vRatio = pOutdoor ? 3.0 : 3.5;
  final rPlan = (
    platformMm: vPlatform,
    frames: math.max(1, (vTotal / towerFrameMm).ceil()),
    totalHeightMm: vTotal,
    needsStabilisers: vTotal > vRatio * pBase.widthMm,
    tooHigh: vPlatform > (pOutdoor ? towerMaxOutdoorMm : towerMaxIndoorMm),
  );

  return rPlan;
}
