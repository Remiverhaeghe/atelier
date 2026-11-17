/// Étagères sur mesure dans une niche (sur tasseaux) ou sous un rampant de combles
/// (montants coupés en biais, tablettes du haut moins profondes).
library;

import 'dart:math' as math;

/// Jeu laissé à la tablette pour l'entrer entre deux murs jamais parfaitement parallèles.
const nicheGapMm = 4;

/// Les tasseaux de côté s'arrêtent avant le bord : on ne les voit pas de face.
const cleatSetbackMm = 20;

/// Une vis tous les 25 cm, au moins deux par tasseau.
int cleatScrews(int pLengthMm) => math.max(2, (pLengthMm / 250).ceil() + 1);

typedef NichePlan = ({int shelfLengthMm, int backCleatMm, int sideCleatMm, int cleats, int screws});

/// [pShelves] tablettes dans une niche de [pWidthMm] sur [pDepthMm], chacune sur trois
/// tasseaux : un au fond, un de chaque côté.
NichePlan planNiche(int pWidthMm, int pDepthMm, int pShelves) {
  final vShelves = math.max(pShelves, 0);
  final vSide = math.max(pDepthMm - cleatSetbackMm, 0);
  final rPlan = (
    shelfLengthMm: math.max(pWidthMm - nicheGapMm, 0),
    backCleatMm: pWidthMm,
    sideCleatMm: vSide,
    cleats: 3 * vShelves,
    screws: vShelves * (cleatScrews(pWidthMm) + 2 * cleatScrews(vSide)),
  );

  return rPlan;
}

typedef SlopeShelf = ({int heightMm, int depthMm});

typedef SlopePlan = ({
  /// Montants : hauteur côté mur (genou) et côté pièce, coupés à l'angle du rampant.
  int sideBackMm,
  int sideFrontMm,
  double bevelDeg,
  List<SlopeShelf> shelves,
});

/// Meuble posé contre un mur de genou de [pKneeWallMm], sous un rampant de [pSlopeDeg],
/// profond de [pDepthMm], avec [pShelves] tablettes régulièrement espacées.
SlopePlan planUnderSlope(int pKneeWallMm, double pSlopeDeg, int pDepthMm, int pShelves) {
  final vTan = math.tan(pSlopeDeg * math.pi / 180);
  final vFront = pKneeWallMm + (pDepthMm * vTan).round();
  final vCount = math.max(pShelves, 1);
  final rPlan = (
    sideBackMm: pKneeWallMm,
    sideFrontMm: vFront,
    bevelDeg: pSlopeDeg,
    shelves: [
      for (var vIndex = 0; vIndex < vCount; vIndex++)
        () {
          // Du sol jusqu'à 10 cm sous le haut du montant côté pièce
          final vHeight = vCount == 1 ? 0 : ((vFront - 100) * vIndex / (vCount - 1)).round();
          // Au-dessus du genou, la tablette recule sous le rampant
          final vSetback = vHeight <= pKneeWallMm || vTan <= 0
              ? 0
              : ((vHeight - pKneeWallMm) / vTan).round();
          return (heightMm: vHeight, depthMm: math.max(pDepthMm - vSetback, 0));
        }(),
    ],
  );

  return rPlan;
}
