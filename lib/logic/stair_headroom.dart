/// Échappée d'un escalier : hauteur libre entre le nez de chaque marche et le dessous du
/// plancher du haut, tant que la marche est encore sous le plancher.
///
/// Même règle que `designStair` : la trémie part du haut de l'escalier, et toute marche dont
/// le nez a moins de 1,90 m au-dessus de lui doit être sous la trémie. Pour un escalier
/// tournant, le calcul suit la ligne de foulée déroulée : l'épure sur place reste nécessaire.
library;

import 'dart:math' as math;

import 'fixtures.dart';
import 'stair_design.dart';

/// Taille par défaut de la personne qui monte, sans chaussures.
const defaultPersonMm = 1800;

typedef StairHeadroom = ({
  StairPlan plan,
  int treads,

  /// Plus petite hauteur libre au-dessus d'une marche couverte par le plancher (la dernière
  /// avant la trémie), ou null si la trémie couvre tout l'escalier.
  int? headroomMm,

  /// Trémie qui donne juste les 1,90 m d'échappée.
  int neededTremieMm,

  /// Marches couvertes avec moins de 1,90 m de hauteur libre.
  int lowTreads,

  /// Première marche (à partir de 1, en montant) où une personne de la taille donnée se
  /// cogne au plancher du haut ; null si elle passe partout.
  int? bumpTread,

  /// Hauteur libre au-dessus du nez de chaque marche, null sous la trémie.
  List<int?> treadHeadroomMm,
});

/// Échappée d'un escalier qui monte [pRiseMm], avec une trémie de [pTremieMm] mesurée
/// depuis l'arrivée, sous un plancher de [pFloorMm] d'épaisseur.
StairHeadroom stairHeadroom(
  int pRiseMm,
  int pTremieMm, {
  int pFloorMm = upperFloorMm,
  int pPersonMm = defaultPersonMm,
}) {
  final vPlan = stairPlan(pRiseMm);
  final vTreads = math.max(vPlan.risers - 1, 0);
  final vUnderside = pRiseMm - pFloorMm;
  final vEdge = vTreads * vPlan.goingMm - pTremieMm;
  // Le nez de la marche i est à (i - 1) girons de l'origine et à i hauteurs de marche
  final vPerTread = <int?>[
    for (var vIndex = 1; vIndex <= vTreads; vIndex++)
      (vIndex - 1) * vPlan.goingMm >= vEdge ? null : vUnderside - vIndex * vPlan.riserMm,
  ];
  final vClearTreads = vPlan.riserMm <= 0
      ? vTreads
      : math.max(0, ((vUnderside - minHeadroomMm) / vPlan.riserMm).floor());
  final vOpenTreads = (vTreads - vClearTreads).clamp(0, vTreads);
  int? vBump;
  int? vMin;
  var vLow = 0;
  for (var vIndex = 0; vIndex < vPerTread.length; vIndex++) {
    final vClear = vPerTread[vIndex];
    if (vClear == null) {
      continue;
    }
    vMin = vMin == null ? vClear : math.min(vMin, vClear);
    if (vClear < minHeadroomMm) {
      vLow++;
    }
    if (vBump == null && vClear < pPersonMm) {
      vBump = vIndex + 1;
    }
  }
  final rHeadroom = (
    plan: vPlan,
    treads: vTreads,
    headroomMm: vMin,
    neededTremieMm: vOpenTreads * vPlan.goingMm,
    lowTreads: vLow,
    bumpTread: vBump,
    treadHeadroomMm: vPerTread,
  );

  return rHeadroom;
}

/// L'échappée est suffisante : 1,90 m au moins au-dessus de chaque marche couverte.
bool headroomOk(StairHeadroom pHeadroom) =>
    pHeadroom.headroomMm == null || pHeadroom.headroomMm! >= minHeadroomMm;
