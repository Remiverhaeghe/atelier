/// Plan de pose du parquet rangée par rangée : longueur de chaque lame, joints décalés, chutes réutilisées.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'parquet.dart';
import 'room.dart';

/// Plus petit morceau de lame que l'on accepte de poser.
const minPieceMm = 300;

/// Une longueur de lames posées bout à bout entre deux murs.
class RowRun {
  const RowRun({
    required this.pieces,
    required this.startsWithOffcut,
    required this.newPlanks,
    required this.jointsOk,
  });

  /// Longueur de chaque morceau, dans l'ordre de pose.
  final List<int> pieces;

  /// La première lame est une chute d'une rangée précédente.
  final bool startsWithOffcut;

  /// Lames neuves entamées pour cette longueur.
  final int newPlanks;

  /// Faux si l'écart minimal entre joints ou la longueur minimale d'un morceau n'a pas pu être tenu.
  final bool jointsOk;

  int get lengthMm => pieces.fold(0, (pSum, pPiece) => pSum + pPiece);
}

/// Une rangée : sa largeur et ses longueurs de pose (plusieurs si un mur la coupe, pièce en L).
class LayingRow {
  const LayingRow({required this.number, required this.widthMm, required this.runs});

  final int number;
  final int widthMm;
  final List<RowRun> runs;
}

class LayingPlan {
  const LayingPlan({required this.rows, required this.planksUsed});

  final List<LayingRow> rows;

  /// Lames neuves entamées pour toute la pièce, chutes réutilisées déduites.
  final int planksUsed;

  /// Numéros des rangées où les règles de pose n'ont pas pu être tenues.
  List<int> get problemRows => [
    for (final vRow in rows)
      if (vRow.runs.any((pRun) => !pRun.jointsOk)) vRow.number,
  ];
}

/// Vrai si les joints de deux rangées commencées à [pStart] et [pPrevious] sont assez écartés.
bool jointsFarEnough(int pStart, int? pPrevious, int pPlankMm, int pMinOffsetMm) {
  if (pPrevious == null) {
    return true;
  }
  final vDelta = (pStart - pPrevious).abs() % pPlankMm;
  final rFarEnough = math.min(vDelta, pPlankMm - vDelta) >= pMinOffsetMm;

  return rFarEnough;
}

class _Start {
  const _Start(this.lengthMm, this.offcutIndex);

  final int lengthMm;

  /// Index de la chute utilisée, ou null pour une lame neuve.
  final int? offcutIndex;
}

class _RunResult {
  const _RunResult(this.run, this.startMm);

  final RowRun run;
  final int startMm;
}

/// Pose d'une longueur [pRunMm] ; [pOffcuts] est mis à jour avec les chutes utilisées et produites.
_RunResult _layRun(int pRunMm, ParquetSettings pSettings, int? pPrevious, List<int> pOffcuts) {
  final vPlank = pSettings.plankLengthMm;
  final vMinOffset = pSettings.minJointOffsetMm;
  if (pRunMm <= vPlank) {
    return _layShortRun(pRunMm, vPlank, pOffcuts);
  }
  final vCandidates = <_Start>[
    // Chutes d'abord, de la plus longue à la plus courte
    for (final vIndex in [
      for (var i = 0; i < pOffcuts.length; i++) i,
    ]..sort((pA, pB) => pOffcuts[pB].compareTo(pOffcuts[pA])))
      if (pOffcuts[vIndex] >= minPieceMm && pOffcuts[vIndex] <= vPlank)
        _Start(pOffcuts[vIndex], vIndex),
    if (pPrevious != null && pPrevious - vMinOffset >= minPieceMm)
      _Start(pPrevious - vMinOffset, null),
    if (pPrevious != null && pPrevious + vMinOffset <= vPlank) _Start(pPrevious + vMinOffset, null),
    _Start(vPlank, null),
  ];
  _Start? vFallback;
  for (final vCandidate in vCandidates) {
    if (!jointsFarEnough(vCandidate.lengthMm, pPrevious, vPlank, vMinOffset)) {
      continue;
    }
    var vStart = vCandidate;
    final vLast = (pRunMm - vStart.lengthMm) % vPlank;
    if (vLast > 0 && vLast < minPieceMm) {
      // Dernier morceau trop court : on raccourcit la première lame neuve d'autant.
      final vShorter = vStart.lengthMm - (minPieceMm - vLast);
      if (vStart.offcutIndex == null &&
          vShorter >= minPieceMm &&
          jointsFarEnough(vShorter, pPrevious, vPlank, vMinOffset)) {
        vStart = _Start(vShorter, null);
      } else {
        vFallback ??= vStart;
        continue;
      }
    }

    return _build(vStart, pRunMm, vPlank, pOffcuts, true);
  }

  return _build(vFallback ?? vCandidates.last, pRunMm, vPlank, pOffcuts, false);
}

_RunResult _layShortRun(int pRunMm, int pPlankMm, List<int> pOffcuts) {
  // La plus petite chute assez longue suffit ; sinon une lame neuve.
  int? vBest;
  for (var vIndex = 0; vIndex < pOffcuts.length; vIndex++) {
    if (pOffcuts[vIndex] >= pRunMm && (vBest == null || pOffcuts[vIndex] < pOffcuts[vBest])) {
      vBest = vIndex;
    }
  }
  final vRest = (vBest == null ? pPlankMm : pOffcuts[vBest]) - pRunMm;
  if (vBest != null) {
    pOffcuts.removeAt(vBest);
  }
  if (vRest >= minPieceMm) {
    pOffcuts.add(vRest);
  }
  final rResult = _RunResult(
    RowRun(
      pieces: [pRunMm],
      startsWithOffcut: vBest != null,
      newPlanks: vBest == null ? 1 : 0,
      jointsOk: true,
    ),
    pRunMm,
  );

  return rResult;
}

_RunResult _build(_Start pStart, int pRunMm, int pPlankMm, List<int> pOffcuts, bool pOk) {
  var vNewPlanks = 0;
  final vOffcutIndex = pStart.offcutIndex;
  if (vOffcutIndex != null) {
    final vOffcut = pOffcuts.removeAt(vOffcutIndex);
    if (vOffcut - pStart.lengthMm >= minPieceMm) {
      pOffcuts.add(vOffcut - pStart.lengthMm);
    }
  } else {
    vNewPlanks++;
    if (pPlankMm - pStart.lengthMm >= minPieceMm) {
      pOffcuts.add(pPlankMm - pStart.lengthMm);
    }
  }
  final vRest = pRunMm - pStart.lengthMm;
  final vFull = vRest ~/ pPlankMm;
  final vLast = vRest - vFull * pPlankMm;
  vNewPlanks += vFull + (vLast > 0 ? 1 : 0);
  if (vLast > 0 && pPlankMm - vLast >= minPieceMm) {
    pOffcuts.add(pPlankMm - vLast);
  }
  final rResult = _RunResult(
    RowRun(
      pieces: [pStart.lengthMm, for (var i = 0; i < vFull; i++) pPlankMm, if (vLast > 0) vLast],
      startsWithOffcut: vOffcutIndex != null,
      newPlanks: vNewPlanks,
      jointsOk: pOk,
    ),
    pStart.lengthMm,
  );

  return rResult;
}

/// Longueurs à poser à la hauteur [pY] du contour aligné, jeu de dilatation déduit aux deux bouts.
List<int> runsAt(List<PlanPoint> pPoints, double pY, int pGapMm) {
  final vCrossings = <double>[];
  for (var vIndex = 0; vIndex < pPoints.length - 1; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[vIndex + 1];
    if ((pY - vA.y) * (pY - vB.y) < 0) {
      vCrossings.add(vA.x + (pY - vA.y) * (vB.x - vA.x) / (vB.y - vA.y));
    }
  }
  vCrossings.sort();
  final rRuns = <int>[
    for (var vIndex = 0; vIndex + 1 < vCrossings.length; vIndex += 2)
      (vCrossings[vIndex + 1] - vCrossings[vIndex]).round() - 2 * pGapMm,
  ]..removeWhere((pLength) => pLength <= 0);

  return rRuns;
}

/// Plan de pose de la pièce ; null pour une pose en motif ou une pièce incomplète.
LayingPlan? planLaying(Room pRoom, ParquetSettings pSettings) {
  final vSplit = splitRows(pRoom, pSettings);
  if (vSplit == null || pSettings.type == ParquetType.herringbone || pSettings.plankLengthMm <= 0) {
    return null;
  }
  final vPoints = alignedOutline(
    pRoom,
    pSettings.layingWallIndex,
    pExtraDeg: layingAngleDeg(pSettings),
  );
  var vY = vPoints.map((pPoint) => pPoint.y).reduce(math.min) + pSettings.expansionGapMm;
  final vOffcuts = <int>[];
  int? vPrevious;
  var vPlanks = 0;
  final rRows = <LayingRow>[];
  for (var vNumber = 1; vNumber <= vSplit.rowCount; vNumber++) {
    final vWidth = vNumber == 1
        ? vSplit.firstRowWidthMm
        : vNumber == vSplit.rowCount
        ? vSplit.lastRowWidthMm
        : pSettings.plankWidthMm;
    final vRuns = <RowRun>[];
    int? vRowStart;
    for (final vLength in runsAt(vPoints, vY + vWidth / 2, pSettings.expansionGapMm)) {
      final vResult = _layRun(vLength, pSettings, vPrevious, vOffcuts);
      vRuns.add(vResult.run);
      vPlanks += vResult.run.newPlanks;
      vRowStart ??= vResult.startMm;
    }
    vPrevious = vRowStart ?? vPrevious;
    rRows.add(LayingRow(number: vNumber, widthMm: vWidth, runs: vRuns));
    vY += vWidth;
  }

  return LayingPlan(rows: rRows, planksUsed: vPlanks);
}
