/// Hauteur d'une mezzanine dans une pièce haute : où placer le plancher pour garder de la
/// place debout dessous et assez de hauteur dessus.
library;

import 'mezzanine.dart';

/// Hauteur libre sous la poutre ou les solives, pour passer debout.
const minClearBelowMm = 2200;

/// En dessous de 1,80 m, la surface ne compte pas en surface habitable.
const minClearAboveMm = 1800;

/// À partir de 2,20 m, on tient debout partout au-dessus.
const standingAboveMm = 2200;

typedef HeightSplit = ({
  /// Dessus du plancher fini, depuis le sol : c'est la hauteur que monte l'escalier.
  int floorTopMm,

  /// Épaisseur sous le plancher fini : panneau et bois le plus bas (poutre ou solives).
  int structureMm,

  /// Hauteur libre dessous, sous le bois le plus bas : c'est aussi la hauteur des poteaux.
  int clearBelowMm,
  int clearAboveMm,

  /// Assez de hauteur au-dessus pour une surface habitable.
  bool fits,
  bool standingAbove,
});

/// Plancher placé au plus bas qui laisse 2,20 m dessous, le reste de [pRoomHeightMm] au-dessus.
HeightSplit splitHeight(int pRoomHeightMm, MezzaninePlan pPlan, int pFloorThicknessMm) {
  final vJoistHeight = pPlan.joist?.heightMm ?? 0;
  final vBeamHeight = pPlan.beams > 0 ? (pPlan.beam?.heightMm ?? 0) : 0;
  final vLowest = vBeamHeight > vJoistHeight ? vBeamHeight : vJoistHeight;
  final vStructure = pFloorThicknessMm + vLowest;
  final vFloorTop = minClearBelowMm + vStructure;
  final vAbove = pRoomHeightMm - vFloorTop;
  final rSplit = (
    floorTopMm: vFloorTop,
    structureMm: vStructure,
    clearBelowMm: minClearBelowMm,
    clearAboveMm: vAbove,
    fits: vAbove >= minClearAboveMm,
    standingAbove: vAbove >= standingAboveMm,
  );

  return rSplit;
}
