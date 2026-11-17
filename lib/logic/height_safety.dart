/// Travail en hauteur : ce qu'il faut vérifier avant de monter, selon la hauteur de travail.
library;

/// Vérifications, dans l'ordre où on les fait.
enum HeightCheck {
  /// Jamais seul : quelqu'un sait où l'on est et peut appeler les secours.
  notAlone,

  /// Escabeau ou plateforme : pieds bloqués, sol plan, jamais sur la dernière marche.
  stepladder,

  /// Plateforme individuelle roulante (PIRL) ou échafaudage : garde-corps tout autour.
  guardrails,

  /// Échafaudage roulant : roues freinées, stabilisateurs sortis, monté selon sa notice.
  towerBraked,

  /// Rien de lourd en hauteur, outils attachés ; zone balisée en dessous.
  zoneBelow,

  /// Toiture ou bord sans garde-corps : harnais accroché à un point d'ancrage.
  harness,

  /// Pas de vent fort ni de pluie pour un travail dehors ou sur un toit.
  weather,
}

/// Vérifications pour travailler à [pWorkHeightMm] (hauteur des pieds), sur un toit si [pRoof].
List<HeightCheck> heightChecks(int pWorkHeightMm, {bool pRoof = false}) => [
  HeightCheck.notAlone,
  if (pWorkHeightMm <= 1000 && !pRoof) HeightCheck.stepladder,
  if (pWorkHeightMm > 1000) HeightCheck.guardrails,
  if (pWorkHeightMm > 1000 && !pRoof) HeightCheck.towerBraked,
  if (pWorkHeightMm > 0) HeightCheck.zoneBelow,
  if (pRoof) HeightCheck.harness,
  if (pRoof) HeightCheck.weather,
];
