/// Conditions de chantier : température et humidité permettent-elles de peindre, coller, vernir ?
library;

import 'dart:math' as math;

/// Produits courants, avec les plages relevées sur les fiches techniques usuelles.
enum SiteProduct {
  acrylicPaint(minC: 8, maxC: 30, maxHumidity: 80),
  alkydPaint(minC: 5, maxC: 30, maxHumidity: 80),
  floorVarnish(minC: 12, maxC: 25, maxHumidity: 70),
  parquetGlue(minC: 15, maxC: 25, minHumidity: 40, maxHumidity: 65),
  tileAdhesive(minC: 5, maxC: 30),
  filler(minC: 5, maxC: 30, maxHumidity: 80),
  sealant(minC: 5, maxC: 40),
  expandingFoam(minC: 5, maxC: 30);

  const SiteProduct({
    required this.minC,
    required this.maxC,
    this.minHumidity = 0,
    this.maxHumidity = 100,
  });

  final double minC;
  final double maxC;
  final double minHumidity;
  final double maxHumidity;

  /// Les finitions filmogènes craignent la condensation sur le support.
  bool get dewSensitive =>
      this == acrylicPaint || this == alkydPaint || this == floorVarnish;
}

/// Raison d'un refus, dans l'ordre où on la vérifie.
enum ConditionIssue { tooCold, tooHot, tooDry, tooHumid, condensation }

/// Écart minimal entre le support et le point de rosée avant de peindre ou vernir.
const dewMarginC = 3.0;

/// Point de rosée par la formule de Magnus.
double dewPointC(double pAirC, double pHumidity) {
  const vA = 17.62;
  const vB = 243.12;
  final vGamma = math.log(pHumidity.clamp(1, 100) / 100) + vA * pAirC / (vB + pAirC);
  final rDew = vB * vGamma / (vA - vGamma);

  return rDew;
}

/// Problèmes pour [pProduct] ; liste vide si on peut y aller. Sans [pSurfaceC], le support
/// est supposé à la température de l'air.
List<ConditionIssue> checkConditions(
  SiteProduct pProduct, {
  required double pAirC,
  required double pHumidity,
  double? pSurfaceC,
}) {
  final vSurface = pSurfaceC ?? pAirC;
  final rIssues = [
    if (math.min(pAirC, vSurface) < pProduct.minC) ConditionIssue.tooCold,
    if (math.max(pAirC, vSurface) > pProduct.maxC) ConditionIssue.tooHot,
    if (pHumidity < pProduct.minHumidity) ConditionIssue.tooDry,
    if (pHumidity > pProduct.maxHumidity) ConditionIssue.tooHumid,
    if (pProduct.dewSensitive && vSurface < dewPointC(pAirC, pHumidity) + dewMarginC)
      ConditionIssue.condensation,
  ];

  return rIssues;
}
