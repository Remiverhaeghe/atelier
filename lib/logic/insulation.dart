/// Isolation : épaisseur selon la résistance thermique visée, paquets, pare-vapeur et suspentes.
library;

import 'dart:math' as math;

/// Paroi à isoler, avec la résistance R courante pour les aides à la rénovation (m².K/W).
enum InsulatedPart {
  lostAttic(7),
  rafters(6),
  walls(3.7),
  floor(3);

  const InsulatedPart(this.targetR);

  final double targetR;

  /// Isolant posé sous une ossature : fourrures et suspentes à prévoir.
  bool get needsFraming => this == rafters || this == walls;
}

/// Isolant, avec sa conductivité λ (W/m.K) et les épaisseurs vendues.
enum Insulant {
  glassWool(0.035, [45, 60, 75, 100, 120, 140, 160, 200, 240]),
  rockWool(0.036, [45, 60, 80, 100, 120, 140, 160, 200]),
  woodFibre(0.038, [40, 60, 80, 100, 120, 140, 160, 200]),
  cellulose(0.040, []),
  polyurethane(0.022, [40, 60, 80, 100, 120]);

  const Insulant(this.lambda, this.thicknessesMm);

  final double lambda;

  /// Épaisseurs vendues ; vide pour un isolant soufflé, à l'épaisseur voulue.
  final List<int> thicknessesMm;
}

/// Isolation calculée pour une surface.
typedef InsulationPlan = ({
  double targetR,
  int neededMm,
  List<int> layersMm,
  double achievedR,
  int packs,
  double vaporBarrierM2,
  int hangers,
});

/// Marge de coupe sur l'isolant et recouvrement du pare-vapeur.
const insulationWastePercent = 5;
const vaporOverlapPercent = 10;

/// Écartement des fourrures et des suspentes sur une fourrure, en mm.
const furringSpacingMm = 600;
const hangerSpacingMm = 1200;

/// Couches à poser : une seule si possible, sinon deux croisées dont la somme suffit.
List<int> _layers(Insulant pInsulant, int pNeededMm) {
  final vSizes = pInsulant.thicknessesMm;
  if (vSizes.isEmpty) {
    // Soufflé : arrondi au centimètre au-dessus
    return [(pNeededMm / 10).ceil() * 10];
  }
  final vSingle = vSizes.where((pSize) => pSize >= pNeededMm).firstOrNull;
  if (vSingle != null) {
    return [vSingle];
  }
  // Deux couches : la plus fine somme qui suffit, la plus épaisse dessous
  List<int>? rBest;
  for (final vA in vSizes) {
    for (final vB in vSizes.where((pSize) => pSize <= vA)) {
      if (vA + vB >= pNeededMm && (rBest == null || vA + vB < rBest[0] + rBest[1])) {
        rBest = [vA, vB];
      }
    }
  }

  return rBest ?? [vSizes.last, vSizes.last];
}

/// Plan d'isolation de [pAreaM2] de [pPart] avec [pInsulant], paquets de [pPackM2] m² par couche.
InsulationPlan planInsulation({
  required InsulatedPart pPart,
  required Insulant pInsulant,
  required double pAreaM2,
  double pPackM2 = 5,
  double? pTargetR,
}) {
  final vTarget = pTargetR ?? pPart.targetR;
  final vNeeded = (vTarget * pInsulant.lambda * 1000 - 1e-6).ceil();
  final vLayers = _layers(pInsulant, vNeeded);
  final vThickness = vLayers.fold(0, (pSum, pLayer) => pSum + pLayer);
  final vToCover = pAreaM2 * (1 + insulationWastePercent / 100);
  final vPacks = pInsulant.thicknessesMm.isEmpty || pPackM2 <= 0
      ? 0
      : vLayers.length * (vToCover / pPackM2 - 1e-9).ceil();
  final vRows = 1e6 / furringSpacingMm / hangerSpacingMm;
  final rPlan = (
    targetR: vTarget,
    neededMm: vNeeded,
    layersMm: vLayers,
    achievedR: vThickness / 1000 / pInsulant.lambda,
    packs: math.max(vPacks, 0),
    // Le plancher bas et les combles perdus soufflés se passent d'un pare-vapeur posé à part
    vaporBarrierM2: pPart == InsulatedPart.floor
        ? 0
        : pAreaM2 * (1 + vaporOverlapPercent / 100),
    hangers: pPart.needsFraming ? (pAreaM2 * vRows).ceil() : 0,
  );

  return rPlan;
}

/// Sacs d'ouate à souffler : densité tassée de 35 kg/m³ en combles perdus, sacs de 12,5 kg.
int celluloseBags(double pAreaM2, int pThicknessMm) =>
    (pAreaM2 * pThicknessMm / 1000 * 35 / 12.5 - 1e-9).ceil();
