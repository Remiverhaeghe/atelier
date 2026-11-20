/// Peindre une grande hauteur (cage d'escalier, pièce sous rampant, séjour cathédrale) :
/// matériel pour atteindre le haut, quantités mur et plafond, ordre de travail sans reprise.
library;

/// Hauteur qu'une personne atteint au rouleau sans manche, bras tendus.
const reachMm = 2000;

/// Manches télescopiques vendus, en mm, du plus court au plus long.
const poleLengthsMm = [1000, 2000, 3000, 4000];

/// Au-delà, un manche trop long ne permet plus d'appuyer le rouleau : il faut monter.
const maxPoleWorkMm = 5000;

/// Au-delà, l'escabeau ne suffit plus pour découper les angles : échafaudage roulant.
const stepladderMaxMm = 3500;

enum HighAccess {
  /// Rouleau à bout de bras.
  roller,

  /// Rouleau sur manche télescopique, depuis le sol.
  telescopicPole,

  /// Manche télescopique pour les aplats, escabeau pour les angles et les découpes.
  poleAndStepladder,

  /// Échafaudage roulant, à monter et déplacer le long du mur.
  scaffold,
}

typedef HighAccessPlan = ({HighAccess access, int? poleMm});

/// Matériel pour peindre jusqu'à [pHeightMm] : le manche le plus court qui suffit, et de quoi
/// découper les angles en haut.
HighAccessPlan highAccess(int pHeightMm) {
  int? vPole;
  for (final vLength in poleLengthsMm) {
    if (vPole == null && reachMm + vLength >= pHeightMm) {
      vPole = vLength;
    }
  }
  final HighAccess vAccess;
  if (pHeightMm <= reachMm + 400) {
    vAccess = HighAccess.roller;
    vPole = null;
  } else if (pHeightMm > maxPoleWorkMm) {
    vAccess = HighAccess.scaffold;
  } else if (pHeightMm > stepladderMaxMm) {
    vAccess = HighAccess.poleAndStepladder;
  } else {
    vAccess = HighAccess.telescopicPole;
  }
  final rPlan = (access: vAccess, poleMm: vPole);

  return rPlan;
}

typedef HighPaintPlan = ({
  double wallM2,
  double ceilingM2,
  double wallLitres,
  double ceilingLitres,
  int wallCans,
  int ceilingCans,
});

/// Pot de peinture courant pour les grandes surfaces.
const highPaintCanL = 10.0;

int _ceil(double pValue) => (pValue - 1e-9).ceil();

/// Quantités pour une pièce de [pPerimeterMm] de tour sur [pHeightMm] de haut, plafond de
/// [pCeilingM2], ouvertures de [pOpeningsM2] déduites, en [pCoats] couches à [pCoverageM2PerL].
HighPaintPlan highPaintPlan({
  required int pPerimeterMm,
  required int pHeightMm,
  required double pCeilingM2,
  double pOpeningsM2 = 0,
  int pCoats = 2,
  double pCoverageM2PerL = 10,
}) {
  final vWall = pPerimeterMm * pHeightMm / 1e6 - pOpeningsM2;
  final vWallM2 = vWall < 0 ? 0.0 : vWall;
  final vCoverage = pCoverageM2PerL <= 0 ? 10.0 : pCoverageM2PerL;
  final vWallL = vWallM2 * pCoats / vCoverage;
  final vCeilingL = pCeilingM2 * pCoats / vCoverage;
  final rPlan = (
    wallM2: vWallM2,
    ceilingM2: pCeilingM2,
    wallLitres: vWallL,
    ceilingLitres: vCeilingL,
    wallCans: _ceil(vWallL / highPaintCanL),
    ceilingCans: _ceil(vCeilingL / highPaintCanL),
  );

  return rPlan;
}

/// Étapes dans l'ordre, pour ne laisser aucune reprise visible.
enum HighPaintStep {
  protect,
  ceilingFirst,
  cutInTop,
  verticalBands,
  wetEdge,
  moveAlong,
  noStopMidWall,
  secondCoat,
}

/// Ordre de travail selon le matériel : avec un échafaudage, on le déplace le long du mur au
/// lieu de peindre le haut puis le bas, ce qui laisserait une ligne de reprise.
List<HighPaintStep> highPaintSteps(HighAccess pAccess) => [
  HighPaintStep.protect,
  HighPaintStep.ceilingFirst,
  HighPaintStep.cutInTop,
  HighPaintStep.verticalBands,
  HighPaintStep.wetEdge,
  if (pAccess == HighAccess.scaffold || pAccess == HighAccess.poleAndStepladder)
    HighPaintStep.moveAlong,
  HighPaintStep.noStopMidWall,
  HighPaintStep.secondCoat,
];
