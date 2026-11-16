/// Sens de pose du parquet : les directions possibles d'une pièce et celle à conseiller.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'parquet.dart';
import 'room.dart';

/// Un sens de pose : lames parallèles au mur [wallIndex] et à ceux de même direction.
class LayingDirection {
  const LayingDirection({
    required this.wallIndex,
    required this.angleDeg,
    required this.wallsLengthMm,
    required this.rowCount,
    required this.recommended,
  });

  /// Mur de référence : le plus long de cette direction.
  final int wallIndex;

  /// Direction des lames sur le plan, entre 0 et 180°.
  final double angleDeg;

  /// Longueur cumulée des murs dans cette direction : plus elle est grande, plus la pièce est
  /// longue dans ce sens.
  final int wallsLengthMm;
  final int rowCount;

  /// Lames dans la longueur de la pièce : les joints se voient moins, la pièce paraît plus grande.
  final bool recommended;
}

/// Écart en dessous duquel deux murs sont considérés comme de même direction.
const _sameDirectionDeg = 3.0;

/// Directions distinctes des murs, la plus longue conseillée, dans l'ordre des murs.
List<LayingDirection> layingDirections(Room pRoom, ParquetSettings pSettings) {
  if (pRoom.walls.length < 3) {
    return const [];
  }
  final vPoints = outline(pRoom);
  final vGroups = <({double angle, int bestWall, int bestLength, int total})>[];
  for (var vIndex = 0; vIndex < pRoom.walls.length; vIndex++) {
    final vStart = vPoints[vIndex];
    final vEnd = vPoints[vIndex + 1];
    final vAngle = math.atan2(vEnd.y - vStart.y, vEnd.x - vStart.x) * 180 / math.pi % 180;
    final vLength = pRoom.walls[vIndex].lengthMm;
    final vGroup = vGroups.indexWhere((pGroup) {
      final vGap = (pGroup.angle - vAngle).abs() % 180;
      return math.min(vGap, 180 - vGap) < _sameDirectionDeg;
    });
    if (vGroup < 0) {
      vGroups.add((angle: vAngle, bestWall: vIndex, bestLength: vLength, total: vLength));
    } else {
      final vOld = vGroups[vGroup];
      vGroups[vGroup] = (
        angle: vOld.angle,
        bestWall: vLength > vOld.bestLength ? vIndex : vOld.bestWall,
        bestLength: math.max(vLength, vOld.bestLength),
        total: vOld.total + vLength,
      );
    }
  }
  final vLongest = vGroups.map((pGroup) => pGroup.total).reduce(math.max);
  final rDirections = [
    for (final vGroup in vGroups)
      LayingDirection(
        wallIndex: vGroup.bestWall,
        angleDeg: vGroup.angle,
        wallsLengthMm: vGroup.total,
        rowCount: splitRows(pRoom, pSettings.copyWith(layingWallIndex: vGroup.bestWall))?.rowCount ?? 0,
        recommended: vGroup.total == vLongest,
      ),
  ];

  return rDirections;
}

/// Sens choisi parmi [pDirections] : celui dont la direction contient le mur de pose réglé.
int selectedDirection(Room pRoom, List<LayingDirection> pDirections, int pWallIndex) {
  final vPoints = outline(pRoom);
  final vIndex = pWallIndex.clamp(0, pRoom.walls.length - 1);
  final vStart = vPoints[vIndex];
  final vEnd = vPoints[vIndex + 1];
  final vAngle = math.atan2(vEnd.y - vStart.y, vEnd.x - vStart.x) * 180 / math.pi % 180;
  final rIndex = pDirections.indexWhere((pDirection) {
    final vGap = (pDirection.angleDeg - vAngle).abs() % 180;
    return math.min(vGap, 180 - vGap) < _sameDirectionDeg;
  });

  return rIndex;
}
