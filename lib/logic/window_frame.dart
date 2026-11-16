/// Remplacement des plexis de toiture : surfaces, cadre en bois à fabriquer et vitrage à commander.
library;

import 'fixtures.dart';
import 'room.dart';

/// Ce qui remplace le plexi, avec son épaisseur.
enum Glazing {
  doubleGlazing(24),
  polycarbonate(16),
  laminatedGlass(9),
  plexi(4);

  const Glazing(this.thicknessMm);

  final int thicknessMm;
}

/// Une taille de plexi et le nombre de fenêtres qui l'ont.
typedef PlexiSize = ({int widthMm, int heightMm, int count, List<String> rooms});

/// Plexis de la maison regroupés par taille, les plus nombreux d'abord.
List<PlexiSize> plexiSizes(List<Room> pRooms) {
  final vBySize = <(int, int), List<String>>{};
  for (final vRoom in pRooms) {
    for (final vFixture in vRoom.fixtures) {
      if (vFixture.kind == FixtureKind.roofWindow && vFixture.plexi) {
        vBySize.putIfAbsent((vFixture.widthMm, vFixture.depthMm), () => []).add(vRoom.name);
      }
    }
  }
  final rSizes = [
    for (final vEntry in vBySize.entries)
      (
        widthMm: vEntry.key.$1,
        heightMm: vEntry.key.$2,
        count: vEntry.value.length,
        rooms: vEntry.value.toSet().toList(),
      ),
  ]..sort((pA, pB) => pB.count.compareTo(pA.count));

  return rSizes;
}

/// Surface totale des plexis, en m².
double plexiAreaM2(List<Room> pRooms) => plexiSizes(
  pRooms,
).fold(0.0, (pSum, pSize) => pSum + pSize.widthMm * pSize.heightMm * pSize.count / 1e6);

/// Jeu laissé entre le cadre et l'ouverture, de chaque côté, pour caler et mousser.
const fitGapMm = 5;

/// Jeu entre le vitrage et le fond de feuillure, de chaque côté.
const glassGapMm = 3;

/// Largeur de la feuillure, où le vitrage prend appui.
const rebateWidthMm = 18;

/// Épaisseur des parcloses qui tiennent le vitrage.
const beadMm = 15;

/// Trait de scie compté à chaque coupe.
const kerfMm = 3;

/// Longueur des tasseaux vendus.
const stockLengthMm = 2400;

/// Cadre fixe à mi-bois : montants et traverses de même longueur que le cadre.
typedef FramePlan = ({
  int outerWidthMm,
  int outerHeightMm,
  int faceMm,
  int depthMm,
  int rebateDepthMm,
  int stileMm,
  int railMm,
  int glassWidthMm,
  int glassHeightMm,
  int beadsMm,
  int stockPieces,
});

/// Cadre pour une ouverture de [pWidthMm] × [pHeightMm] (cotes du chevêtre ou du tableau).
FramePlan? planFrame(int pWidthMm, int pHeightMm, Glazing pGlazing) {
  // Bois de 45 mm de face ; l'épaisseur suit le vitrage, sa parclose et un talon de 15 mm
  const vFace = 45;
  final vRebateDepth = pGlazing.thicknessMm + glassGapMm + beadMm;
  final vDepth = ((vRebateDepth + 15) / 5).ceil() * 5;
  final vOuterW = pWidthMm - 2 * fitGapMm;
  final vOuterH = pHeightMm - 2 * fitGapMm;
  final vClearW = vOuterW - 2 * vFace;
  final vClearH = vOuterH - 2 * vFace;
  if (vClearW < 100 || vClearH < 100) {
    return null;
  }
  final vGlassW = vClearW + 2 * rebateWidthMm - 2 * glassGapMm;
  final vGlassH = vClearH + 2 * rebateWidthMm - 2 * glassGapMm;
  // Parcloses d'onglet, au fond de la feuillure
  final vBeads = 2 * (vClearW + 2 * rebateWidthMm) + 2 * (vClearH + 2 * rebateWidthMm);
  final vPieces = [vOuterH, vOuterH, vOuterW, vOuterW];
  final rPlan = (
    outerWidthMm: vOuterW,
    outerHeightMm: vOuterH,
    faceMm: vFace,
    depthMm: vDepth,
    rebateDepthMm: vRebateDepth,
    stileMm: vOuterH,
    railMm: vOuterW,
    glassWidthMm: vGlassW,
    glassHeightMm: vGlassH,
    beadsMm: vBeads,
    stockPieces: _stockPieces(vPieces),
  );

  return rPlan;
}

/// Tasseaux à acheter : on range les morceaux du plus long au plus court, trait de scie compris.
int _stockPieces(List<int> pPieces) {
  final vRemaining = <int>[];
  for (final vPiece in [...pPieces]..sort((pA, pB) => pB.compareTo(pA))) {
    final vNeeded = vPiece + kerfMm;
    final vIndex = vRemaining.indexWhere((pLeft) => pLeft >= vNeeded);
    if (vIndex >= 0) {
      vRemaining[vIndex] -= vNeeded;
    } else {
      vRemaining.add(stockLengthMm - vNeeded);
    }
  }

  return vRemaining.length;
}

/// Tailles courantes de fenêtres de toit (largeur × hauteur du dormant, en mm). Les codes
/// changent d'un fabricant à l'autre ; les dimensions, elles, sont partagées.
const roofWindowSizes = [
  (550, 780),
  (550, 980),
  (660, 1180),
  (780, 980),
  (780, 1180),
  (780, 1400),
  (940, 1400),
  (1140, 1180),
];

/// Jeu à laisser entre le dormant et le chevêtre, de chaque côté, pour le raccord d'étanchéité.
const roofFitGapMm = 10;

/// Taille courante la plus proche d'une ouverture, et ce qu'il faut reprendre au chevêtre :
/// positif pour agrandir, négatif pour réduire (tasseau ou cale).
typedef RoofWindowMatch = ({int widthMm, int heightMm, int widenMm, int heightenMm});

RoofWindowMatch nearestRoofWindow(int pWidthMm, int pHeightMm) {
  var vBest = roofWindowSizes.first;
  var vBestScore = double.infinity;
  for (final vSize in roofWindowSizes) {
    final vNeededW = vSize.$1 + 2 * roofFitGapMm - pWidthMm;
    final vNeededH = vSize.$2 + 2 * roofFitGapMm - pHeightMm;
    // Agrandir un chevêtre veut dire couper un chevron : on pénalise la largeur gagnée
    final vScore = (vNeededW > 0 ? 3 * vNeededW : -vNeededW) + vNeededH.abs().toDouble();
    if (vScore < vBestScore) {
      vBestScore = vScore;
      vBest = vSize;
    }
  }
  final rMatch = (
    widthMm: vBest.$1,
    heightMm: vBest.$2,
    widenMm: vBest.$1 + 2 * roofFitGapMm - pWidthMm,
    heightenMm: vBest.$2 + 2 * roofFitGapMm - pHeightMm,
  );

  return rMatch;
}
