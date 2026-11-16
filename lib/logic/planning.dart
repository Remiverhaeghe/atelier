/// Planning d'une pièce : l'ordre des travaux, ce qui bloque quoi, et les temps de séchage.
library;

import 'baseboard.dart';
import 'laying_plan.dart';
import 'room.dart';

/// Phases dans l'ordre où on les fait : du plus salissant au plus fragile.
enum WorkPhase {
  /// Reprises : enduit, rebouchage, ponçage.
  touchUps,
  ceiling,
  walls,
  woodwork,
  parquet,
  baseboards,

  /// Joints de finition des plinthes.
  sealing,
}

/// Noms gardés dans [Room.doneSteps] pour les phases cochées à la main.
const ceilingPaintedStep = 'paintCeiling';
const wallsPaintedStep = 'paintWalls';
const woodworkPaintedStep = 'paintWoodwork';
const sealedStep = 'sealJoints';

/// Séchage indicatif après une phase, en heures ; la notice du produit fait foi.
const dryingHours = {
  WorkPhase.touchUps: 24,
  WorkPhase.ceiling: 6,
  WorkPhase.walls: 24,
  WorkPhase.woodwork: 24,
  WorkPhase.sealing: 24,
};

/// Une phase prévue dans la pièce et son état.
typedef PhaseState = ({WorkPhase phase, bool done});

/// Phases prévues dans la pièce, dans l'ordre, avec leur état.
List<PhaseState> roomPhases(Room pRoom) {
  final vRows = planLaying(pRoom, pRoom.parquet)?.rows ?? const <LayingRow>[];
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard).length;
  bool vStep(String pName) => pRoom.doneSteps.contains(pName);
  final rPhases = <PhaseState>[
    if (pRoom.touchUps.isNotEmpty)
      (phase: WorkPhase.touchUps, done: pRoom.touchUps.every((pTouchUp) => pTouchUp.done)),
    if (pRoom.paint.ceiling) (phase: WorkPhase.ceiling, done: vStep(ceilingPaintedStep)),
    if (pRoom.paint.walls) (phase: WorkPhase.walls, done: vStep(wallsPaintedStep)),
    if (pRoom.paint.woodwork) (phase: WorkPhase.woodwork, done: vStep(woodworkPaintedStep)),
    if (vRows.isNotEmpty)
      (phase: WorkPhase.parquet, done: vRows.every((pRow) => pRoom.laidRows.contains(pRow.number))),
    if (vPieces > 0)
      (
        phase: WorkPhase.baseboards,
        done: pRoom.cutPieces.where((pIndex) => pIndex < vPieces).length == vPieces,
      ),
    if (vPieces > 0 && pRoom.baseboard.fixing != BaseboardFixing.clips)
      (phase: WorkPhase.sealing, done: vStep(sealedStep)),
  ];

  return rPhases;
}

/// Prochaine phase à faire et celle d'avant, pour rappeler le séchage ; null si tout est fait.
({WorkPhase next, WorkPhase? after})? nextPhase(Room pRoom) {
  final vPhases = roomPhases(pRoom);
  final vIndex = vPhases.indexWhere((pState) => !pState.done);
  if (vIndex < 0) {
    return null;
  }

  return (next: vPhases[vIndex].phase, after: vIndex == 0 ? null : vPhases[vIndex - 1].phase);
}
