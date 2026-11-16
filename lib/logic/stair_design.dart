/// Escalier droit dessiné : marches, trémie nécessaire pour l'échappée, débit des limons et
/// des marches.
library;

import 'dart:math' as math;

import 'fixtures.dart';

/// Hauteur libre au-dessus du nez de marche, à respecter partout.
const minHeadroomMm = 1900;

/// Épaisseur du plancher du haut, sous laquelle on passe.
const upperFloorMm = 200;

/// Débord de la marche sur la suivante (nez) et surlongueur des limons pour les coupes.
const noseMm = 30;
const stringerExtraMm = 200;

typedef StairDesign = ({
  StairPlan plan,
  int treads,
  int treadDepthMm,
  int stringerMm,
  int tremieMm,
  bool headroomOk,
});

/// Escalier pour monter [pRiseMm] ; avec [pTremieMm], vérifie que la trémie suffit à l'échappée.
StairDesign designStair(int pRiseMm, {int? pTremieMm}) {
  final vPlan = stairPlan(pRiseMm);
  final vTreads = math.max(vPlan.risers - 1, 0);
  // Marches dont le nez passe à moins de 1,90 m sous le plancher du haut
  final vClear = (pRiseMm - upperFloorMm - minHeadroomMm) / vPlan.riserMm;
  final vOpenTreads = (vTreads - math.max(0, vClear.floor())).clamp(0, vTreads).toInt();
  final vTremie = vOpenTreads * vPlan.goingMm;
  final rDesign = (
    plan: vPlan,
    treads: vTreads,
    treadDepthMm: vPlan.goingMm + noseMm,
    stringerMm: (math.sqrt(math.pow(vPlan.runMm, 2) + math.pow(pRiseMm, 2)) + stringerExtraMm)
        .round(),
    tremieMm: vTremie,
    headroomOk: pTremieMm == null || pTremieMm >= vTremie,
  );

  return rDesign;
}
