/// Plan de la maison : les pièces placées les unes par rapport aux autres.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';
import 'worksite.dart';

/// Pas d'aimantation en déplaçant une pièce : 5 cm.
const houseSnapMm = 50;

/// Point de la pièce dans le repère de la maison : quart(s) de tour puis décalage.
PlanPoint toHouse(Room pRoom, PlanPoint pPoint) {
  final (vX, vY) = switch (pRoom.houseQuarterTurns % 4) {
    1 => (-pPoint.y, pPoint.x),
    2 => (-pPoint.x, -pPoint.y),
    3 => (pPoint.y, -pPoint.x),
    _ => (pPoint.x, pPoint.y),
  };

  return PlanPoint(vX + pRoom.houseXMm, vY + pRoom.houseYMm);
}

/// Contour de la pièce dans le repère de la maison.
List<PlanPoint> houseOutline(Room pRoom) => [
  for (final vPoint in outline(pRoom)) toHouse(pRoom, vPoint),
];

/// Pièces à dessiner : celles qui ont des murs.
List<Room> houseRooms(Worksite pWorksite) =>
    pWorksite.rooms.where((pRoom) => pRoom.walls.length >= 3).toList();

/// Arrondi au pas d'aimantation.
int snap(double pMm) => (pMm / houseSnapMm).round() * houseSnapMm;

/// Range les pièces pas encore placées côte à côte, de gauche à droite, 50 cm d'écart.
List<Room> arrangeUnplaced(List<Room> pRooms) {
  var vCursor = 0.0;
  final rRooms = <Room>[];
  for (final vRoom in pRooms) {
    final vPlaced = vRoom.houseXMm != 0 || vRoom.houseYMm != 0 || vRoom.houseQuarterTurns != 0;
    if (vPlaced || vRoom.walls.length < 3) {
      rRooms.add(vRoom);
      continue;
    }
    final vXs = outline(vRoom).map((pPoint) => pPoint.x);
    final vMinX = vXs.reduce(math.min);
    rRooms.add(vRoom.copyWith(houseXMm: snap(vCursor - vMinX)));
    vCursor += vXs.reduce(math.max) - vMinX + 500;
  }

  return rRooms;
}

/// Niveaux de la maison qui ont au moins une pièce, du plus bas au plus haut ; le
/// rez-de-chaussée est toujours là, même vide.
List<int> houseLevels(List<Room> pRooms) {
  final rLevels = {0, for (final vRoom in pRooms) vRoom.level}.toList()..sort();

  return rLevels;
}

/// Épaisseur d'un plancher entre deux niveaux.
const floorThicknessMm = 200;

/// Hauteur d'étage : plus haut plafond du niveau, 2,50 m s'il est vide, plus le plancher.
int _storeyMm(List<Room> pRooms, int pLevel) {
  final vHeights = pRooms
      .where((pRoom) => pRoom.level == pLevel)
      .map((pRoom) => pRoom.ceilingHeightMm);
  final rStorey = (vHeights.isEmpty ? 2500 : vHeights.reduce(math.max)) + floorThicknessMm;

  return rStorey;
}

/// Altitude du sol d'un niveau, le rez-de-chaussée à 0 et le sous-sol en dessous.
int levelBaseMm(List<Room> pRooms, int pLevel) {
  var rBase = 0;
  for (var vLevel = 0; vLevel < pLevel; vLevel++) {
    rBase += _storeyMm(pRooms, vLevel);
  }
  for (var vLevel = -1; vLevel >= pLevel; vLevel--) {
    rBase -= _storeyMm(pRooms, vLevel);
  }

  return rBase;
}
