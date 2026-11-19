/// Placard sous rampant : le bas des combles, trop bas pour se tenir debout, devient du
/// rangement fermé.
///
/// La façade se pose là où le rampant atteint la hauteur voulue ; derrière, des montants coupés
/// à l'angle du toit séparent des modules à une porte. En bas, un bac sur roulettes va chercher
/// le fond, là où le bras n'arrive pas.
library;

import 'dart:math' as math;

/// Largeur maximale d'une porte, et socle sous les portes.
const eavesDoorMaxMm = 600;
const eavesPlinthMm = 100;

/// Bac sur roulettes : jeu au fond et sur les côtés, hauteur maximale.
const binBackGapMm = 50;
const binSideGapMm = 20;
const binMaxHeightMm = 400;

/// Place à garder au-dessus des bacs pour une tablette utile.
const shelfRoomMm = 300;

/// Panneaux de 2,80 × 2,07 m, et ce qu'on perd en chutes.
const eavesPanelM2 = 2.8 * 2.07;
const eavesPanelWaste = 0.15;

typedef EavesShelf = ({int heightMm, int depthMm});

typedef EavesPlan = ({
  int depthMm,
  int modules,
  int moduleMm,
  int sides,
  int doorHeightMm,
  int hingesPerDoor,
  int binWidthMm,
  int binDepthMm,
  int binHeightMm,
  EavesShelf? shelf,
  int panels,
  int litres,
});

/// Charnières d'une porte de [pHeightMm] : deux jusqu'à 90 cm, une de plus par 70 cm.
int eavesHinges(int pHeightMm) => pHeightMm <= 900 ? 2 : (pHeightMm <= 1600 ? 3 : 4);

/// Placard long de [pLengthMm] contre un mur de genou de [pKneeWallMm], sous un rampant de
/// [pSlopeDeg], avec une façade haute de [pFrontMm]. Null si la façade n'est pas plus haute
/// que le genou ou si le rampant est à plat.
EavesPlan? planEavesStorage({
  required int pKneeWallMm,
  required double pSlopeDeg,
  required int pLengthMm,
  required int pFrontMm,
}) {
  final vTan = math.tan(pSlopeDeg * math.pi / 180);
  if (pFrontMm <= pKneeWallMm || vTan <= 0 || pLengthMm <= 0) {
    return null;
  }
  final vDepth = ((pFrontMm - pKneeWallMm) / vTan).round();
  final vModules = (pLengthMm / eavesDoorMaxMm).ceil();
  final vModule = (pLengthMm / vModules).round();
  final vDoor = pFrontMm - eavesPlinthMm;
  final vBinHeight = math.min(pKneeWallMm - binBackGapMm, binMaxHeightMm);
  // Une tablette au-dessus des bacs : toujours sous le genou, donc sur toute la profondeur
  final vShelfHeight = vBinHeight + binBackGapMm;
  final vShelf = pFrontMm - vShelfHeight >= shelfRoomMm
      ? (heightMm: vShelfHeight, depthMm: vDepth)
      : null;
  final vSidesM2 = (vModules + 1) * vDepth * (pKneeWallMm + pFrontMm) / 2 / 1e6;
  final vFloorM2 = pLengthMm * vDepth / 1e6;
  final vShelfM2 = vShelf == null ? 0.0 : pLengthMm * vShelf.depthMm / 1e6;
  final vDoorsM2 = vModules * vModule * vDoor / 1e6;
  final vPanelsM2 = (vSidesM2 + vFloorM2 + vShelfM2 + vDoorsM2) * (1 + eavesPanelWaste);
  final rPlan = (
    depthMm: vDepth,
    modules: vModules,
    moduleMm: vModule,
    sides: vModules + 1,
    doorHeightMm: vDoor,
    hingesPerDoor: eavesHinges(vDoor),
    binWidthMm: vModule - 2 * binSideGapMm,
    binDepthMm: math.max(vDepth - binBackGapMm, 0),
    binHeightMm: math.max(vBinHeight, 0),
    shelf: vShelf,
    panels: (vPanelsM2 / eavesPanelM2 - 1e-9).ceil(),
    litres: (vDepth * (pKneeWallMm + pFrontMm) / 2 * pLengthMm / 1e6).round(),
  );

  return rPlan;
}
