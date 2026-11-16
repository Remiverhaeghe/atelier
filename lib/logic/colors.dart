/// Aide à la déco : couleurs qui s'accordent avec une teinte de départ.
library;

import 'dart:math' as math;

/// Couleur en teinte (0 à 360), saturation et luminosité (0 à 1).
typedef Hsl = ({double hue, double saturation, double lightness});

/// Couleur 0xRRGGBB en teinte, saturation, luminosité.
Hsl toHsl(int pRgb) {
  final vR = ((pRgb >> 16) & 0xFF) / 255;
  final vG = ((pRgb >> 8) & 0xFF) / 255;
  final vB = (pRgb & 0xFF) / 255;
  final vMax = math.max(vR, math.max(vG, vB));
  final vMin = math.min(vR, math.min(vG, vB));
  final vLight = (vMax + vMin) / 2;
  if (vMax == vMin) {
    return (hue: 0, saturation: 0, lightness: vLight);
  }
  final vDelta = vMax - vMin;
  final vSat = vLight > 0.5 ? vDelta / (2 - vMax - vMin) : vDelta / (vMax + vMin);
  final double vHue;
  if (vMax == vR) {
    vHue = ((vG - vB) / vDelta + (vG < vB ? 6 : 0)) * 60;
  } else if (vMax == vG) {
    vHue = ((vB - vR) / vDelta + 2) * 60;
  } else {
    vHue = ((vR - vG) / vDelta + 4) * 60;
  }

  return (hue: vHue, saturation: vSat, lightness: vLight);
}

/// Teinte, saturation, luminosité en couleur 0xRRGGBB.
int fromHsl(Hsl pColor) {
  final vHue = pColor.hue % 360 / 360;
  final vSat = pColor.saturation.clamp(0.0, 1.0);
  final vLight = pColor.lightness.clamp(0.0, 1.0);
  int vChannel(double pValue) => (pValue * 255).round().clamp(0, 255);
  if (vSat == 0) {
    final vGrey = vChannel(vLight);
    return (vGrey << 16) | (vGrey << 8) | vGrey;
  }
  final vQ = vLight < 0.5 ? vLight * (1 + vSat) : vLight + vSat - vLight * vSat;
  final vP = 2 * vLight - vQ;
  double vPart(double pT) {
    final vT = pT < 0 ? pT + 1 : (pT > 1 ? pT - 1 : pT);
    if (vT < 1 / 6) {
      return vP + (vQ - vP) * 6 * vT;
    }
    if (vT < 1 / 2) {
      return vQ;
    }
    if (vT < 2 / 3) {
      return vP + (vQ - vP) * (2 / 3 - vT) * 6;
    }
    return vP;
  }

  return (vChannel(vPart(vHue + 1 / 3)) << 16) |
      (vChannel(vPart(vHue)) << 8) |
      vChannel(vPart(vHue - 1 / 3));
}

/// Accords proposés autour d'une teinte de départ.
enum Harmony {
  /// Teintes voisines : ambiance calme.
  analogous,

  /// Teinte opposée, adoucie : une touche de contraste.
  complementary,

  /// Même teinte, très claire : pour le plafond et les grands murs.
  soft,

  /// Même teinte, plus foncée : un mur d'accent.
  deep,
}

/// Couleurs de chaque accord, en 0xRRGGBB.
Map<Harmony, List<int>> harmonies(int pBase) {
  final vBase = toHsl(pBase);
  Hsl vShift(double pHue, {double? pSat, double? pLight}) => (
    hue: vBase.hue + pHue,
    saturation: pSat ?? vBase.saturation,
    lightness: pLight ?? vBase.lightness,
  );
  final rHarmonies = {
    Harmony.analogous: [fromHsl(vShift(-30)), fromHsl(vShift(30))],
    Harmony.complementary: [fromHsl(vShift(180, pSat: vBase.saturation * 0.6))],
    Harmony.soft: [fromHsl(vShift(0, pSat: vBase.saturation * 0.4, pLight: 0.93))],
    Harmony.deep: [fromHsl(vShift(0, pLight: vBase.lightness * 0.6))],
  };

  return rHarmonies;
}

/// Teintes de départ courantes pour des murs.
const wallPalette = [
  0xF3EFE6, // blanc cassé
  0xE6DCCB, // lin
  0xCFCFCB, // gris perle
  0xA7B8A0, // vert sauge
  0xC8775A, // terracotta
  0x2F3E55, // bleu nuit
  0xD9A93F, // jaune moutarde
  0x1F5A3A, // vert sapin
];
