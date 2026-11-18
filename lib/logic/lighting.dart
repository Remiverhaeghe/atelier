/// Éclairer une pièce, grande hauteur comprise : flux lumineux, nombre de points et
/// quadrillage, par la méthode du facteur d'utilisation.
library;

import 'dart:math' as math;

/// Usage de la pièce et éclairement conseillé au sol, en lux.
enum LightUse {
  corridor(lux: 100),
  living(lux: 200),
  bathroom(lux: 200),
  kitchen(lux: 300),
  workshop(lux: 500);

  const LightUse({required this.lux});

  final int lux;
}

/// Flux des lampes LED courantes, en lumens.
const lampLumensChoices = [800, 1500, 3000, 5000];

/// Poussière et vieillissement des lampes.
const lightMaintenanceFactor = 0.8;

/// Rendement courant d'une lampe LED.
const lumensPerWatt = 100;

/// Part du flux qui arrive au sol : moins la lampe est haute, plus elle éclaire utile.
double utilisationFactor(int pHeightMm) {
  final rFactor = pHeightMm <= 2700 ? 0.6 : (pHeightMm <= 4000 ? 0.5 : 0.4);

  return rFactor;
}

typedef LightingPlan = ({int lumens, int lamps, int columns, int rows, int spacingMm, int watts});

/// Points lumineux de [pLampLumens] pour une pièce de [pLengthMm] × [pWidthMm], lampes à
/// [pHeightMm] : écart entre lampes d'au plus 1,5 fois leur hauteur pour un éclairage égal.
LightingPlan planLighting({
  required int pLengthMm,
  required int pWidthMm,
  required int pHeightMm,
  required LightUse pUse,
  required int pLampLumens,
}) {
  final vLength = math.max(1, pLengthMm);
  final vWidth = math.max(1, pWidthMm);
  final vArea = vLength * vWidth / 1e6;
  final vFactor = utilisationFactor(pHeightMm) * lightMaintenanceFactor;
  final vLumens = (pUse.lux * vArea / vFactor - 1e-9).ceil();
  final vNeeded = math.max(1, (vLumens / pLampLumens - 1e-9).ceil());
  var vColumns = math.max(1, math.sqrt(vNeeded * vLength / vWidth).round());
  var vRows = (vNeeded / vColumns).ceil();
  final vMaxSpacing = 1.5 * math.max(1, pHeightMm);
  while (vLength / vColumns > vMaxSpacing) {
    vColumns++;
  }
  while (vWidth / vRows > vMaxSpacing) {
    vRows++;
  }
  final vLamps = vColumns * vRows;
  final rPlan = (
    lumens: vLumens,
    lamps: vLamps,
    columns: vColumns,
    rows: vRows,
    spacingMm: math.max(vLength / vColumns, vWidth / vRows).round(),
    watts: (vLamps * pLampLumens / lumensPerWatt).ceil(),
  );

  return rPlan;
}
