/// Gouttières et descentes : section selon la surface de toit, pente, crochets.
library;

import 'dart:math' as math;

/// Règle courante : 1 cm² de section de descente par mètre carré de toiture mesuré en plan.
const descentCm2PerM2 = 1.0;

/// Diamètres de descente courants, en millimètres.
const descentDiametersMm = [60, 80, 100, 120];

/// Au-delà, l'eau met trop longtemps à rejoindre la descente : une de plus.
const gutterMaxRunMm = 12000;

/// Pente conseillée : 5 mm par mètre vers la descente.
const gutterSlopeMmPerM = 5;

/// Un crochet tous les 50 cm, plus un à chaque bout.
const hookSpacingMm = 500;

typedef GutterPlan = ({
  double roofM2,
  int descents,
  int diameterMm,
  int dropMm,
  int hooks,
});

double descentSectionCm2(int pDiameterMm) => math.pi * math.pow(pDiameterMm / 20, 2);

/// Gouttière de [pGutterMm] qui reçoit un pan de [pDepthMm] mesuré au sol (en plan) : nombre de
/// descentes, diamètre qui suffit, dénivelé à donner, crochets.
GutterPlan planGutter(int pGutterMm, int pDepthMm) {
  final vRoof = pGutterMm * pDepthMm / 1e6;
  // Assez de descentes pour la longueur, et pour que la plus grosse suffise à chacune
  final vLargest = descentSectionCm2(descentDiametersMm.last);
  final vDescents = pGutterMm <= 0
      ? 0
      : [
          1,
          (pGutterMm / gutterMaxRunMm - 1e-9).ceil(),
          (vRoof * descentCm2PerM2 / vLargest - 1e-9).ceil(),
        ].reduce(math.max);
  final vPerDescent = vDescents == 0 ? 0.0 : vRoof * descentCm2PerM2 / vDescents;
  final vDiameter = descentDiametersMm.firstWhere(
    (pDiameter) => descentSectionCm2(pDiameter) >= vPerDescent,
    orElse: () => descentDiametersMm.last,
  );
  // Une descente à un bout : toute la longueur en pente ; plusieurs : de chaque côté
  final vRun = vDescents <= 1 ? pGutterMm : pGutterMm / (2 * vDescents);
  final rPlan = (
    roofM2: vRoof,
    descents: vDescents,
    diameterMm: vDiameter,
    dropMm: (vRun / 1000 * gutterSlopeMmPerM).ceil(),
    hooks: pGutterMm <= 0 ? 0 : (pGutterMm / hookSpacingMm - 1e-9).ceil() + 1,
  );

  return rPlan;
}
