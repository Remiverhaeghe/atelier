/// Avant de commencer : coupures et protections à prévoir pour chaque étape du guide.
library;

import 'guidance.dart';

enum SafetyCheck {
  powerOff,
  waterOff,
  dustMask,
  goggles,
  gloves,
  earProtection,
  kneePads,
  ventilate,
}

/// Ce qu'on vérifie avant l'étape, dans l'ordre où on le fait.
List<SafetyCheck> stepSafety(GuideStep pStep) => switch (pStep) {
  GuideStep.acclimatise || GuideStep.traceAxis || GuideStep.dryFitCorners => const [],
  GuideStep.prepareFloor => const [
    SafetyCheck.dustMask,
    SafetyCheck.kneePads,
    SafetyCheck.ventilate,
  ],
  GuideStep.undercutCasings => const [
    SafetyCheck.goggles,
    SafetyCheck.earProtection,
    SafetyCheck.dustMask,
  ],
  GuideStep.unrollUnderlay ||
  GuideStep.spacers ||
  GuideStep.removeSpacers => const [SafetyCheck.kneePads],
  GuideStep.spreadGlue => const [SafetyCheck.gloves, SafetyCheck.ventilate, SafetyCheck.kneePads],
  GuideStep.fixJoists => const [SafetyCheck.powerOff, SafetyCheck.waterOff, SafetyCheck.goggles],
  GuideStep.firstRow || GuideStep.lastRow => const [SafetyCheck.kneePads, SafetyCheck.goggles],
  GuideStep.nailInTongue => const [SafetyCheck.goggles, SafetyCheck.earProtection],
  GuideStep.fitThresholds => const [SafetyCheck.goggles, SafetyCheck.earProtection],
  GuideStep.cutBaseboards => const [
    SafetyCheck.goggles,
    SafetyCheck.earProtection,
    SafetyCheck.dustMask,
  ],
  // Percer ou clouer près d'une prise : on coupe le circuit avant
  GuideStep.fixBaseboards => const [SafetyCheck.powerOff, SafetyCheck.goggles],
  GuideStep.sealJoints => const [SafetyCheck.gloves, SafetyCheck.ventilate],
};
