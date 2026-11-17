/// Trémie dans un plancher sur solives : solives coupées, chevêtre et solives d'enchevêtrure.
///
/// La trémie part du bord d'appui (mur ou poutre) : les solives coupées, dites boiteuses,
/// vont du chevêtre à l'autre appui. Le chevêtre porte la moitié de leur portée et se
/// décharge sur deux solives d'enchevêtrure doublées, de chaque côté de la trémie.
/// Même prédimensionnement que la mezzanine : à faire valider.
library;

import 'mezzanine.dart';

typedef OpeningPlan = ({
  /// Solives interrompues par la trémie.
  int cutJoists,

  /// Longueur des solives boiteuses, du chevêtre à l'appui opposé.
  int tailLengthMm,

  /// Section de chaque bois du chevêtre doublé, ou null si aucune ne suffit.
  Section? header,

  /// Section de chaque bois des solives d'enchevêtrure doublées.
  Section? trimmer,

  /// Sabots : deux pour le chevêtre, un par solive boiteuse.
  int hangers,

  /// La trémie est plus longue que la portée : elle coupe le plancher en deux.
  bool tooLong,
});

/// Trémie de [pWidthMm] en travers des solives et [pLengthMm] dans leur sens.
OpeningPlan planOpening(Mezzanine pFloor, int pWidthMm, int pLengthMm) {
  final vSpacing = pFloor.joistSpacingMm <= 0 ? 400 : pFloor.joistSpacingMm;
  final vSpan = pFloor.depthMm;
  final vCut = pWidthMm <= 0 ? 0 : (pWidthMm / vSpacing).ceil() - 1;
  final vTail = vSpan - pLengthMm;
  final vTooLong = pLengthMm >= vSpan;

  // Chevêtre : la moitié de la portée des solives boiteuses, sur la largeur de la trémie
  final vHeaderService = pFloor.serviceKnPerM2 * (vTail < 0 ? 0 : vTail) / 2000;
  final vHeaderUltimate = pFloor.ultimateKnPerM2 * (vTail < 0 ? 0 : vTail) / 2000;
  Section? vDoubled(int pSpanMm, double pService, double pUltimate) => joistSections
      .where(
        (pSection) => beamHolds(
          (widthMm: 2 * pSection.widthMm, heightMm: pSection.heightMm),
          c24,
          pSpanMm,
          pService,
          pUltimate,
        ),
      )
      .firstOrNull;
  final vHeader = vDoubled(pWidthMm, vHeaderService, vHeaderUltimate);

  // Solive d'enchevêtrure : sa bande de plancher, plus la moitié du chevêtre ramenée en
  // charge répartie équivalente (2P / L : même moment qu'une charge au milieu)
  final vHalfHeaderKn = vHeaderUltimate * pWidthMm / 2000;
  final vHalfHeaderServiceKn = vHeaderService * pWidthMm / 2000;
  final vTrimmer = vDoubled(
    vSpan,
    pFloor.serviceKnPerM2 * vSpacing / 1000 + 2 * vHalfHeaderServiceKn * 1000 / vSpan,
    pFloor.ultimateKnPerM2 * vSpacing / 1000 + 2 * vHalfHeaderKn * 1000 / vSpan,
  );

  final rPlan = (
    cutJoists: vCut,
    tailLengthMm: vTail < 0 ? 0 : vTail,
    header: vHeader,
    trimmer: vTrimmer,
    hangers: vCut == 0 ? 0 : 2 + vCut,
    tooLong: vTooLong,
  );

  return rPlan;
}
