/// Châssis fixe en bois sur mesure, pour remplacer un plexi par un double vitrage : montants
/// et traverses assemblés à tenon et mortaise, feuillure, vitrage et parcloses.
///
/// Règles de menuiserie courantes : 5 mm de jeu de pose autour du dormant, tenon d'un tiers
/// de l'épaisseur et de deux tiers de la largeur du bois, vitrage pris de 18 mm en feuillure
/// avec 4 mm de jeu tout autour pour les cales.
library;

import 'dart:math' as math;

/// Double vitrage courant 4/16/4.
const glassThicknessMm = 24;

/// Jeu entre le vitrage et le fond de feuillure, rattrapé par les cales.
const glassClearanceMm = 4;

/// Profondeur de prise du vitrage dans la feuillure.
const rebateDepthMm = 18;

/// Joint de chaque côté du vitrage, et épaisseur de la parclose qui le tient.
const glazingSealMm = 3;
const beadThicknessMm = 15;

/// Jeu de pose entre le châssis et l'ouverture, de chaque côté.
const fittingGapMm = 5;

/// Poids d'un double vitrage 4/16/4.
const glassKgPerM2 = 20.0;

/// Bois laissé devant la feuillure : en dessous, le châssis devient fragile.
const minLipMm = 20;

typedef WoodWindow = ({
  int outerWidthMm,
  int outerHeightMm,
  int stileLengthMm,
  int railLengthMm,
  int tenonLengthMm,
  int tenonThicknessMm,
  int daylightWidthMm,
  int daylightHeightMm,
  int glassWidthMm,
  int glassHeightMm,
  double glassKg,
  int rebateWidthMm,
  int beadLengthMm,
  bool frameTooThin,
});

/// Châssis pour une ouverture de [pWidthMm] × [pHeightMm], bois de [pFrameWidthMm] de large
/// (vu de face) et [pFrameDepthMm] d'épaisseur.
WoodWindow planWoodWindow({
  required int pWidthMm,
  required int pHeightMm,
  int pFrameWidthMm = 58,
  int pFrameDepthMm = 70,
}) {
  final vOuterWidth = math.max(0, pWidthMm - 2 * fittingGapMm);
  final vOuterHeight = math.max(0, pHeightMm - 2 * fittingGapMm);
  final vTenon = (pFrameWidthMm * 2 / 3).round();
  final vDaylightWidth = math.max(0, vOuterWidth - 2 * pFrameWidthMm);
  final vDaylightHeight = math.max(0, vOuterHeight - 2 * pFrameWidthMm);
  final vGrip = 2 * (rebateDepthMm - glassClearanceMm);
  final vGlassWidth = vDaylightWidth + vGrip;
  final vGlassHeight = vDaylightHeight + vGrip;
  final vRebate = glassThicknessMm + 2 * glazingSealMm + beadThicknessMm;
  final rWindow = (
    outerWidthMm: vOuterWidth,
    outerHeightMm: vOuterHeight,
    stileLengthMm: vOuterHeight,
    // Traverse : entre les montants, plus un tenon à chaque bout
    railLengthMm: vDaylightWidth + 2 * vTenon,
    tenonLengthMm: vTenon,
    tenonThicknessMm: (pFrameDepthMm / 3).round(),
    daylightWidthMm: vDaylightWidth,
    daylightHeightMm: vDaylightHeight,
    glassWidthMm: vGlassWidth,
    glassHeightMm: vGlassHeight,
    glassKg: vGlassWidth * vGlassHeight / 1e6 * glassKgPerM2,
    rebateWidthMm: vRebate,
    beadLengthMm: 2 * (vGlassWidth + vGlassHeight),
    frameTooThin: pFrameDepthMm - vRebate < minLipMm,
  );

  return rWindow;
}
