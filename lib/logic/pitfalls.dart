/// Erreurs fréquentes, rappelées avant l'étape où on les commet.
library;

import 'guidance.dart';

enum Pitfall {
  openPacksEarly,
  wetScreed,
  unevenFloor,
  undercutTooHigh,
  underlayOverlap,
  vaporBarrierGaps,
  glueSkinned,
  glueUnderdosed,
  joistsNotLevel,
  crookedFirstWall,
  noExpansionGap,
  tongueTowardsWall,
  plankDirection,
  spacersMoved,
  splitTongue,
  narrowLastRow,
  spacersLeft,
  thresholdScrewed,
  miterWrongWay,
  shortMeasure,
  skipDryFit,
  baseboardOnFloor,
  siliconeToPaint,
}

/// Pièges de chaque étape, du plus courant au moins courant.
List<Pitfall> stepPitfalls(GuideStep pStep) => switch (pStep) {
  GuideStep.acclimatise => [Pitfall.openPacksEarly],
  GuideStep.prepareFloor => [Pitfall.unevenFloor, Pitfall.wetScreed],
  GuideStep.undercutCasings => [Pitfall.undercutTooHigh],
  GuideStep.unrollUnderlay => [Pitfall.underlayOverlap, Pitfall.vaporBarrierGaps],
  GuideStep.spreadGlue => [Pitfall.glueSkinned, Pitfall.glueUnderdosed],
  GuideStep.fixJoists => [Pitfall.joistsNotLevel],
  GuideStep.traceAxis => [Pitfall.crookedFirstWall, Pitfall.plankDirection],
  GuideStep.firstRow => [Pitfall.noExpansionGap, Pitfall.tongueTowardsWall],
  GuideStep.spacers => [Pitfall.spacersMoved],
  GuideStep.nailInTongue => [Pitfall.splitTongue],
  GuideStep.lastRow => [Pitfall.narrowLastRow],
  GuideStep.removeSpacers => [Pitfall.spacersLeft],
  GuideStep.fitThresholds => [Pitfall.thresholdScrewed],
  GuideStep.cutBaseboards => [Pitfall.miterWrongWay, Pitfall.shortMeasure],
  GuideStep.dryFitCorners => [Pitfall.skipDryFit],
  GuideStep.fixBaseboards => [Pitfall.baseboardOnFloor],
  GuideStep.sealJoints => [Pitfall.siliconeToPaint],
};

/// Prochaine étape à faire dans l'ordre du guide, celle dont on rappelle les pièges.
GuideStep? nextStep(List<GuideStep> pSteps, List<String> pDone) =>
    pSteps.where((pStep) => !pDone.contains(pStep.name)).firstOrNull;
