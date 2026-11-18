/// Embrasure d'une fenêtre de toit : le tunnel qui traverse chevrons et isolant jusqu'au
/// plafond. Habillée droite, elle fait de l'ombre ; le haut horizontal et le bas vertical
/// laissent entrer le plus de lumière, comme le recommandent les fabricants.
library;

import 'dart:math' as math;

typedef RoofLining = ({
  /// Habillage du haut, horizontal : profondeur de la fenêtre au plafond.
  int topMm,

  /// Habillage du bas, vertical.
  int bottomMm,

  /// Ouverture dans le plafond rampant, le long de la pente.
  int ceilingOpeningMm,

  /// Gain d'ouverture par rapport à une embrasure droite.
  int gainMm,

  /// Plaques à découper pour les quatre côtés.
  double boardM2,
});

/// Embrasure d'une fenêtre de [pWindowWidthMm] × [pWindowHeightMm] dans un rampant à
/// [pSlopeDeg], sur [pDepthMm] d'épaisseur (chevrons, isolant, plaque).
RoofLining planRoofLining({
  required int pWindowWidthMm,
  required int pWindowHeightMm,
  required int pDepthMm,
  required double pSlopeDeg,
}) {
  final vSlope = pSlopeDeg.clamp(5.0, 85.0) * math.pi / 180;
  final vDepth = math.max(0, pDepthMm);
  final vUp = vDepth / math.tan(vSlope);
  final vDown = vDepth * math.tan(vSlope);
  final vTop = vDepth / math.sin(vSlope);
  final vBottom = vDepth / math.cos(vSlope);
  final vOpening = pWindowHeightMm + vUp + vDown;
  // Côtés : trapèzes entre la fenêtre et l'ouverture du plafond
  final vSide = vDepth * (pWindowHeightMm + vOpening) / 2;
  final rLining = (
    topMm: vTop.round(),
    bottomMm: vBottom.round(),
    ceilingOpeningMm: vOpening.round(),
    gainMm: (vUp + vDown).round(),
    boardM2: (pWindowWidthMm * (vTop + vBottom) + 2 * vSide) / 1e6,
  );

  return rLining;
}
