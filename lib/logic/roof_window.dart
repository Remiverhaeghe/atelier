/// Remplacer un plexi (ou ouvrir le toit) par une fenêtre de toit : quelle largeur passe
/// entre les chevrons, quand faut-il un chevêtre, quelle hauteur selon la pente.
library;

/// Largeurs et hauteurs de fenêtres de toit vendues couramment, en mm hors tout.
const roofWindowWidthsMm = [550, 660, 780, 940, 1140, 1340];
const roofWindowHeightsMm = [780, 980, 1180, 1400, 1600];

/// Jeu de pose de chaque côté de la fenêtre, pour le raccord d'étanchéité et l'isolant.
const roofWindowGapMm = 30;

/// Couverture : le raccord d'étanchéité n'est pas le même.
enum RoofCover {
  /// Tuiles mécaniques ou romanes, en relief.
  profiledTiles,

  /// Ardoises, tuiles plates, bardeaux : matériaux plats.
  flat,
}

typedef RoofWindowFit = ({
  /// Vide entre deux chevrons.
  int clearWidthMm,

  /// Fenêtre la plus large qui passe sans toucher aux chevrons.
  int? widestWithoutCutMm,

  /// Fenêtre retenue : la plus étroite qui couvre la largeur voulue.
  int? chosenWidthMm,

  /// Il faut couper un chevron et poser un chevêtre pour la largeur voulue.
  bool needsHeader,
  int heightMm,
});

/// Fenêtre pour une ouverture de [pWantedWidthMm] entre chevrons de [pRafterWidthMm] posés
/// tous les [pSpacingMm], sur un toit de [pSlopeDeg].
RoofWindowFit fitRoofWindow({
  required int pSpacingMm,
  required int pRafterWidthMm,
  required int pWantedWidthMm,
  required double pSlopeDeg,
}) {
  final vClear = pSpacingMm - pRafterWidthMm;
  int? vWidest(int pClear) =>
      roofWindowWidthsMm.where((pWidth) => pWidth + 2 * roofWindowGapMm <= pClear).lastOrNull;
  final vWithout = vWidest(vClear);
  final vFits = roofWindowWidthsMm
      .where((pWidth) => pWidth >= pWantedWidthMm && pWidth + 2 * roofWindowGapMm <= vClear)
      .firstOrNull;
  // Un chevron coupé : le vide passe à deux entraxes moins un chevron
  final vWithHeader = roofWindowWidthsMm
      .where(
        (pWidth) =>
            pWidth >= pWantedWidthMm &&
            pWidth + 2 * roofWindowGapMm <= 2 * pSpacingMm - pRafterWidthMm,
      )
      .firstOrNull;
  // Plus le toit est couché, plus la fenêtre doit être haute pour voir dehors
  final vHeight = pSlopeDeg < 30 ? 1400 : (pSlopeDeg <= 45 ? 1180 : 980);
  final rFit = (
    clearWidthMm: vClear,
    widestWithoutCutMm: vWithout,
    chosenWidthMm: vFits ?? vWithHeader,
    needsHeader: vFits == null && vWithHeader != null,
    heightMm: vHeight,
  );

  return rFit;
}
