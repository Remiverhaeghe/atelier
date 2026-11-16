/// Avancement des travaux d'une pièce : rangées de parquet posées et plinthes coupées.
library;

import 'baseboard.dart';
import 'laying_plan.dart';
import 'room.dart';

/// Tâches faites et tâches à faire dans une pièce.
class RoomProgress {
  const RoomProgress({required this.done, required this.total});

  final int done;
  final int total;

  /// Part faite, entre 0 et 1 ; 0 tant qu'il n'y a rien à faire.
  double get ratio => total == 0 ? 0 : done / total;
}

/// Une rangée posée et un morceau coupé comptent chacun pour une tâche.
RoomProgress roomProgress(Room pRoom) {
  final vRows = planLaying(pRoom, pRoom.parquet)?.rows ?? const [];
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  final vRowsDone = vRows.where((pRow) => pRoom.laidRows.contains(pRow.number)).length;
  final vPiecesDone = pRoom.cutPieces.where((pIndex) => pIndex < vPieces.length).length;
  final rProgress = RoomProgress(
    done: vRowsDone + vPiecesDone,
    total: vRows.length + vPieces.length,
  );

  return rProgress;
}
