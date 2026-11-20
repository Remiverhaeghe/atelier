/// Sécurité par outil : protections à porter, gestes interdits et vérifications avant de
/// brancher (ou de monter, ou d'ouvrir le pot).
library;

import 'dart:math' as math;

/// Protections à porter. Plus large que celles des gestes de base : les machines demandent
/// aussi une visière, des chaussures de sécurité ou un masque à cartouche.
enum Protection {
  glasses,
  faceShield,
  earmuffs,
  dustMask,
  vapourMask,
  cutGloves,
  chemicalGloves,
  safetyShoes,
  fittedClothes,
}

/// Outils et produits qui blessent le plus souvent un débutant.
///
/// [checks] et [forbidden] : nombre de vérifications et de gestes interdits de la fiche, dans
/// l'ordre des textes. [noLooseGloves] : la machine tourne, un gant ample peut être happé.
/// [noisy] : outil bruyant, à garder pour les heures où le voisinage le tolère.
enum SafetyTool {
  circularSaw(
    protections: [
      Protection.glasses,
      Protection.earmuffs,
      Protection.dustMask,
      Protection.fittedClothes,
    ],
    checks: 4,
    forbidden: 4,
    noLooseGloves: true,
    noisy: true,
  ),
  router(
    protections: [
      Protection.glasses,
      Protection.earmuffs,
      Protection.dustMask,
      Protection.fittedClothes,
    ],
    checks: 4,
    forbidden: 3,
    noLooseGloves: true,
    noisy: true,
  ),
  grinder(
    protections: [
      Protection.faceShield,
      Protection.earmuffs,
      Protection.dustMask,
      Protection.cutGloves,
      Protection.safetyShoes,
      Protection.fittedClothes,
    ],
    checks: 4,
    forbidden: 4,
    noLooseGloves: false,
    noisy: true,
  ),
  ladder(
    protections: [Protection.safetyShoes],
    checks: 4,
    forbidden: 4,
    noLooseGloves: false,
    noisy: false,
  ),
  finishes(
    protections: [Protection.glasses, Protection.vapourMask, Protection.chemicalGloves],
    checks: 4,
    forbidden: 3,
    noLooseGloves: false,
    noisy: false,
  );

  const SafetyTool({
    required this.protections,
    required this.checks,
    required this.forbidden,
    required this.noLooseGloves,
    required this.noisy,
  });

  final List<Protection> protections;
  final int checks;
  final int forbidden;
  final bool noLooseGloves;
  final bool noisy;
}

/// Vrai quand toutes les vérifications de [pTool] sont cochées dans [pDone] (leurs numéros).
bool readyToStart(SafetyTool pTool, Set<int> pDone) =>
    Iterable<int>.generate(pTool.checks).every(pDone.contains);

/// Distance du pied d'une échelle au mur pour une hauteur d'appui [pHeightMm] : le quart de la
/// hauteur, ce qui donne un angle d'environ 75°.
int ladderFootMm(int pHeightMm) {
  final rFoot = (pHeightMm / 4).round();

  return rFoot;
}

/// Longueur d'échelle pour s'appuyer à [pHeightMm], en dépassant d'un mètre au-dessus de
/// l'appui quand on doit y accéder (un toit, une mezzanine).
int ladderLengthMm(int pHeightMm, {bool pStepOff = false}) {
  final vFoot = ladderFootMm(pHeightMm);
  final vRail = math.sqrt(pHeightMm * pHeightMm + vFoot * vFoot).round();
  final rLength = vRail + (pStepOff ? 1000 : 0);

  return rLength;
}
