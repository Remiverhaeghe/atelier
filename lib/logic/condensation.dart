/// Condensation : l'eau de l'air se dépose sur une surface plus froide que son point de rosée.
///
/// Le point de rosée vient de la formule de Magnus ; la température d'une paroi, de sa
/// résistance thermique : plus elle laisse passer la chaleur (coefficient U élevé), plus son
/// côté intérieur se rapproche de la température du dehors.
library;

import 'dart:math' as math;

/// Constantes de Magnus pour l'eau liquide, valables de −45 à 60 °C.
const magnusA = 17.62;
const magnusB = 243.12;

/// Résistance superficielle intérieure d'une paroi verticale, en m²·K/W.
const insideSurfaceResistance = 0.13;

/// Écart sous lequel la paroi est jugée « à la limite » : un courant d'air froid ou une nuit
/// plus fraîche suffit à la faire perler.
const closeMarginC = 3.0;

/// Parois courantes et leur coefficient U, en W/m²·K.
enum Wall {
  singleGlazing(5.8),
  acrylicSheet(5.0),
  doubleGlazing(2.8),
  bareRoof(2.5),
  bareWall(2.0),
  insulatedWall(0.3),
  insulatedRoof(0.2);

  const Wall(this.uValue);

  final double uValue;
}

enum CondensationRisk { none, close, condensation }

typedef CondensationCheck = ({double dewPointC, double surfaceC, CondensationRisk risk});

/// Point de rosée de l'air à [pTempC] et [pHumidityPercent] d'humidité relative.
double dewPoint(double pTempC, double pHumidityPercent) {
  final vHumidity = pHumidityPercent.clamp(1, 100) / 100;
  final vGamma = math.log(vHumidity) + magnusA * pTempC / (magnusB + pTempC);
  final rDew = magnusB * vGamma / (magnusA - vGamma);

  return rDew;
}

/// Température du côté pièce de [pWall], quand il fait [pInsideC] dedans et [pOutsideC] dehors.
double surfaceTemperature(Wall pWall, double pInsideC, double pOutsideC) {
  final vShare = (pWall.uValue * insideSurfaceResistance).clamp(0.0, 1.0);
  final rSurface = pInsideC - vShare * (pInsideC - pOutsideC);

  return rSurface;
}

/// Risque de condensation sur [pWall] pour l'air de la pièce et la température du dehors.
CondensationCheck checkCondensation({
  required Wall pWall,
  required double pInsideC,
  required double pHumidityPercent,
  required double pOutsideC,
}) {
  final vDew = dewPoint(pInsideC, pHumidityPercent);
  final vSurface = surfaceTemperature(pWall, pInsideC, pOutsideC);
  final vRisk = vSurface <= vDew
      ? CondensationRisk.condensation
      : vSurface - vDew < closeMarginC
      ? CondensationRisk.close
      : CondensationRisk.none;
  final rCheck = (dewPointC: vDew, surfaceC: vSurface, risk: vRisk);

  return rCheck;
}

/// Humidité relative à ne pas dépasser dans la pièce pour que [pWall] reste sèche.
double maxHumidityFor(Wall pWall, double pInsideC, double pOutsideC) {
  final vSurface = surfaceTemperature(pWall, pInsideC, pOutsideC);
  double vSaturation(double pTempC) => math.exp(magnusA * pTempC / (magnusB + pTempC));
  final rMax = (100 * vSaturation(vSurface) / vSaturation(pInsideC)).clamp(0.0, 100.0);

  return rMax;
}
