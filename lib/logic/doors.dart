/// Porte intérieure à changer : bloc-porte standard qui entre dans l'ouverture existante.
library;

/// Largeurs de vantail courantes (mm) et hauteur standard.
const doorLeafWidthsMm = [630, 730, 830, 930];
const doorLeafHeightMm = 2040;

/// Le bloc-porte (huisserie comprise) demande environ 7 cm de plus que le vantail en largeur et
/// 6 cm en hauteur dans l'ouverture brute.
const frameExtraWidthMm = 70;
const frameExtraHeightMm = 60;

/// Épaisseurs de cloison courantes ; au-delà, une huisserie à recouvrement réglable ou un
/// élargisseur.
const wallThicknessesMm = [72, 100];

typedef DoorMatch = ({
  int? leafWidthMm,
  int widthGapMm,
  bool heightFits,
  int heightGapMm,
  bool adjustableFrame,
});

/// Plus grand bloc-porte standard qui entre dans l'ouverture brute ; le jeu restant se cale et
/// se cache sous les chambranles.
DoorMatch matchDoor({
  required int pOpeningWidthMm,
  required int pOpeningHeightMm,
  required int pWallMm,
}) {
  int? vLeaf;
  for (final vWidth in doorLeafWidthsMm) {
    if (vWidth + frameExtraWidthMm <= pOpeningWidthMm) {
      vLeaf = vWidth;
    }
  }
  final vNeededHeight = doorLeafHeightMm + frameExtraHeightMm;
  final rMatch = (
    leafWidthMm: vLeaf,
    widthGapMm: vLeaf == null ? 0 : pOpeningWidthMm - vLeaf - frameExtraWidthMm,
    heightFits: pOpeningHeightMm >= vNeededHeight,
    heightGapMm: pOpeningHeightMm - vNeededHeight,
    adjustableFrame: !wallThicknessesMm.any((pThickness) => (pThickness - pWallMm).abs() <= 5),
  );

  return rMatch;
}

/// Sens d'ouverture : on se place du côté où la porte s'éloigne en la poussant ; les paumelles
/// à droite donnent une porte « poussant droit ».
enum DoorHand { pushRight, pushLeft }
