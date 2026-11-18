/// Étanchéité d'une fenêtre posée dans un mur : ce qui empêche l'eau, l'air et la vapeur de
/// passer, de l'extérieur vers l'intérieur.
///
/// Dehors, l'eau doit ruisseler et partir : mastic au pourtour, appui en pente avec goutte
/// d'eau. Entre le cadre et le mur, une mousse imprégnée (compribande) gonfle et ferme le
/// jeu. Dedans, un adhésif pare-vapeur empêche l'humidité de la pièce d'entrer dans le joint.
library;

import 'dart:math' as math;

/// Cartouche de mastic courante.
const cartridgeMl = 310;

/// Cordon de mastic du vitrage (6 × 6 mm) et du pourtour extérieur (10 × 10 mm).
const glazingBeadMm2 = 36;
const outsideBeadMm2 = 100;

/// Pertes en bout de cartouche et au lissage.
const sealantWaste = 0.1;

/// Rouleau d'adhésif pare-vapeur.
const vapourTapeRollM = 25;

/// Rouleau de mousse imprégnée.
const foamRollM = 5.6;

/// Pente minimale de l'appui vers l'extérieur, et débord de la goutte d'eau.
const sillSlopePercent = 10;
const dripOverhangMm = 30;

/// Mousses imprégnées du commerce : le jeu qu'elles ferment, de tant à tant de millimètres.
const foamRanges = [(2, 6), (3, 7), (5, 9), (7, 12), (10, 18)];

typedef WindowSealing = ({
  int glazingSealantM,
  int glazingCartridges,
  int outsideSealantM,
  int outsideCartridges,
  int foamM,
  int foamRolls,
  (int, int)? foam,
  int vapourTapeM,
  int vapourTapeRolls,
});

int _cartridges(double pLengthMm, int pBeadMm2) {
  final vMl = pLengthMm * pBeadMm2 / 1000 * (1 + sealantWaste);

  return (vMl / cartridgeMl - 1e-9).ceil();
}

/// Étanchéité d'un cadre de [pFrameWidthMm] × [pFrameHeightMm] posé avec [pGapMm] de jeu,
/// vitrage de [pGlassWidthMm] × [pGlassHeightMm] mastiqué des deux côtés.
WindowSealing planWindowSealing({
  required int pFrameWidthMm,
  required int pFrameHeightMm,
  required int pGapMm,
  required int pGlassWidthMm,
  required int pGlassHeightMm,
}) {
  final vFrame = 2.0 * (math.max(0, pFrameWidthMm) + math.max(0, pFrameHeightMm));
  final vGlass = 2.0 * 2 * (math.max(0, pGlassWidthMm) + math.max(0, pGlassHeightMm));
  final vFoam = foamRanges.where((pRange) => pRange.$1 <= pGapMm && pGapMm <= pRange.$2);
  final rSealing = (
    glazingSealantM: (vGlass / 1000).ceil(),
    glazingCartridges: _cartridges(vGlass, glazingBeadMm2),
    outsideSealantM: (vFrame / 1000).ceil(),
    outsideCartridges: _cartridges(vFrame, outsideBeadMm2),
    // La mousse fait trois côtés : en bas, le cadre repose sur l'appui et son joint
    foamM: ((vFrame - pFrameWidthMm) / 1000).ceil(),
    foamRolls: ((vFrame - pFrameWidthMm) / 1000 / foamRollM - 1e-9).ceil(),
    foam: vFoam.firstOrNull,
    vapourTapeM: (vFrame / 1000).ceil(),
    vapourTapeRolls: (vFrame / 1000 / vapourTapeRollM - 1e-9).ceil(),
  );

  return rSealing;
}
