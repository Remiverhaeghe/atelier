/// Garde-corps et main courante d'un escalier droit (NF P01-012) : le long de la volée,
/// côté vide, et main courante côté mur.
library;

import 'dart:math' as math;

import 'mezzanine_floor.dart';
import 'stair_design.dart';

/// Hauteur de la main courante, mesurée à l'aplomb du nez de marche.
const stairRailHeightMm = 900;

typedef StairRailing = ({
  /// Longueur en pente d'un côté de la volée.
  int lengthMm,
  int openSides,
  int posts,
  int balusters,

  /// Mains courantes, côté vide et côté mur, mises bout à bout.
  int handrailMm,
});

/// Garde-corps de l'escalier [pDesign] qui monte [pRiseMm], avec [pOpenSides] côtés dans le
/// vide (0 entre deux murs, 1 contre un mur, 2 au milieu de la pièce).
StairRailing planStairRailing(StairDesign pDesign, int pRiseMm, {int pOpenSides = 1}) {
  final vSides = pOpenSides.clamp(0, 2).toInt();
  final vLength = math.sqrt(math.pow(pDesign.plan.runMm, 2) + math.pow(pRiseMm, 2)).round();
  final vSide = planGuardrail(vLength);
  final rRailing = (
    lengthMm: vLength,
    openSides: vSides,
    posts: vSide.posts * vSides,
    balusters: vSide.balusters * vSides,
    // Entre deux murs, une main courante suffit ; sinon une par côté
    handrailMm: vLength * math.max(1, vSides == 1 ? 2 : vSides),
  );

  return rRailing;
}
