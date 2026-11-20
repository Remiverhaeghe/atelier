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

/// Jeu sous une porte intérieure : environ 1 cm pour laisser passer l'air vers la VMC.
const doorUndercutMm = 10;

/// Hauteur courante de la poignée et plage confortable pour tous, mesurées depuis le sol fini.
const handleHeightMm = 1050;
const handleMinMm = 900;
const handleMaxMm = 1300;

/// Ce qu'il faut recouper sous la porte quand le sol monte de [pNewFloorMm] et qu'il reste
/// [pCurrentGapMm] sous le vantail ; 0 si le jeu suffit encore.
int doorTrimMm({required int pCurrentGapMm, required int pNewFloorMm}) {
  final vTrim = pNewFloorMm + doorUndercutMm - pCurrentGapMm;
  final rTrim = vTrim < 0 ? 0 : vTrim;

  return rTrim;
}

/// Poignée dans la plage confortable, mesurée depuis le sol fini.
bool handleHeightOk(int pHeightMm) => pHeightMm >= handleMinMm && pHeightMm <= handleMaxMm;

/// Sens d'ouverture déduit de la porte vue du côté où on la pousse : paumelles à droite, la
/// porte est « poussant droit ».
DoorHand doorHandFrom({required bool pHingesRight, required bool pPushing}) {
  final vRight = pPushing ? pHingesRight : !pHingesRight;
  final rHand = vRight ? DoorHand.pushRight : DoorHand.pushLeft;

  return rHand;
}
