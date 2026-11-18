/// Coupe d'une pièce sous rampants : hauteur au faîtage, surface au-dessus de 1,80 m,
/// longueur des rampants et plaques de plâtre à poser.
///
/// Les applis de plan mesurent mal les plafonds en pente ; ici la pièce est décrite par
/// ce qu'on mesure vraiment sous les combles : largeur au sol, hauteur de la jambette
/// (le petit mur bas), angle du rampant et, s'il existe, plafond plat sous le faîtage.
library;

import 'dart:math' as math;

/// Hauteur sous laquelle la surface ne compte pas comme habitable (loi Carrez).
const carrezHeightMm = 1800;

typedef AtticSection = ({
  /// Point le plus haut : faîtage, ou plafond plat s'il est plus bas.
  int topMm,

  /// Largeur au sol où l'on tient debout (au moins 1,80 m sous plafond).
  int usableWidthMm,

  /// Longueur d'un rampant, de la jambette au faîtage ou au plafond plat.
  int rafterLengthMm,

  /// Largeur du plafond plat, 0 sans plafond plat.
  int flatWidthMm,

  /// Largeur au sol trop basse, le long de chaque jambette.
  int lowStripMm,

  /// Plaques de plâtre par mètre de longueur de pièce : jambettes, rampants, plafond plat.
  double boardM2PerMetre,
});

/// Coupe d'une pièce de [pWidthMm] de large entre jambettes, rampant à [pSlopeDeg].
///
/// [pTwoPitches] : rampant des deux côtés (sous un faîtage), sinon un seul côté contre
/// un mur droit. [pCeilingMm] : hauteur d'un plafond plat sous le faîtage, s'il y en a un.
AtticSection atticSection({
  required int pWidthMm,
  required int pKneeWallMm,
  required double pSlopeDeg,
  required bool pTwoPitches,
  int? pCeilingMm,
}) {
  final vWidth = math.max(0, pWidthMm);
  final vKnee = math.max(0, pKneeWallMm);
  final vSlope = pSlopeDeg.clamp(1.0, 89.0) * math.pi / 180;
  final vTan = math.tan(vSlope);
  final vSides = pTwoPitches ? 2 : 1;
  final vRun = vWidth / vSides;
  final vRidge = vKnee + vRun * vTan;
  var vTop = vRidge;
  if (pCeilingMm != null && pCeilingMm > vKnee) {
    vTop = math.min(vRidge, pCeilingMm.toDouble());
  }
  final vSlopedRun = ((vTop - vKnee) / vTan).clamp(0.0, vRun);
  final vFlat = vWidth - vSides * vSlopedRun;
  final vRafter = vSlopedRun / math.cos(vSlope);
  final vLow = vKnee >= carrezHeightMm ? 0.0 : math.min(vRun, (carrezHeightMm - vKnee) / vTan);
  final vUsable = vTop < carrezHeightMm ? 0.0 : vWidth - vSides * vLow;
  final rSection = (
    topMm: vTop.round(),
    usableWidthMm: vUsable.round(),
    rafterLengthMm: vRafter.round(),
    flatWidthMm: vFlat.round(),
    lowStripMm: vLow.round(),
    boardM2PerMetre: (vSides * (vKnee + vRafter) + vFlat) / 1000,
  );

  return rSection;
}
