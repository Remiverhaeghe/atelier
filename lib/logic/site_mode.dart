/// Mode chantier : la prochaine coupe de plinthe et la prochaine rangée de parquet.
library;

import 'laying_plan.dart';
import 'room.dart';

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
