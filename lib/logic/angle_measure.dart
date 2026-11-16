/// Angle réel d'un coin mesuré sans rapporteur : deux repères sur les murs et leur écart.
library;

import 'dart:math' as math;

/// Angle intérieur du coin, arrondi au demi-degré, ou null si les mesures sont impossibles.
///
/// [pSideAMm] et [pSideBMm] : distance du coin à chaque repère ; [pDiagonalMm] : écart entre
/// les repères. Pour un coin sortant, les repères sont pris à l'extérieur et l'angle de la
/// pièce est le complément à 360°.
double? cornerAngle({
  required int pSideAMm,
  required int pSideBMm,
  required int pDiagonalMm,
  bool pOutside = false,
}) {
  final vA = pSideAMm.toDouble();
  final vB = pSideBMm.toDouble();
  final vC = pDiagonalMm.toDouble();
  // Les trois longueurs doivent former un vrai triangle
  if (vA <= 0 || vB <= 0 || vC <= 0 || vC >= vA + vB || vC <= (vA - vB).abs()) {
    return null;
  }
  final vCosine = (vA * vA + vB * vB - vC * vC) / (2 * vA * vB);
  final vMeasured = math.acos(vCosine.clamp(-1.0, 1.0)) * 180 / math.pi;
  final vInterior = pOutside ? 360 - vMeasured : vMeasured;
  final rAngle = (vInterior * 2).round() / 2;

  return rAngle;
}
