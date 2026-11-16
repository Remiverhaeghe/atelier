/// Mode chantier : la prochaine coupe de plinthe et la prochaine rangée de parquet.
library;

import 'baseboard.dart';
import 'laying_plan.dart';
import 'room.dart';

/// Prochain morceau de plinthe pas encore coupé, avec son rang dans la liste ; null s'il n'en reste plus.
({int index, BaseboardPiece piece})? nextBaseboardCut(Room pRoom) {
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  for (var vIndex = 0; vIndex < vPieces.length; vIndex++) {
    if (!pRoom.cutPieces.contains(vIndex)) {
      return (index: vIndex, piece: vPieces[vIndex]);
    }
  }

  return null;
}

/// Prochaine rangée de parquet pas encore posée ; null sans plan de pose ou si tout est posé.
LayingRow? nextLayingRow(Room pRoom) {
  final vPlan = planLaying(pRoom, pRoom.parquet);
  if (vPlan == null) {
    return null;
  }
  for (final vRow in vPlan.rows) {
    if (!pRoom.laidRows.contains(vRow.number)) {
      return vRow;
    }
  }

  return null;
}

/// Pièce avec un morceau de plinthe de plus marqué coupé.
Room markCut(Room pRoom, int pIndex) =>
    pRoom.copyWith(cutPieces: ({...pRoom.cutPieces, pIndex}.toList()..sort()));

/// Pièce avec une rangée de plus marquée posée.
Room markLaid(Room pRoom, int pRow) =>
    pRoom.copyWith(laidRows: ({...pRoom.laidRows, pRow}.toList()..sort()));
