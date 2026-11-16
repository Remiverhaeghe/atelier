/// Réseaux cachés dans les murs : gaines, tuyaux et câbles relevés, et contrôle avant de percer.
library;

import 'dart:math' as math;

import 'room.dart';

enum NetworkKind { electric, water, drain, gas, heating, data }

/// Tracé droit sur un mur, en élévation : position le long du mur depuis son début, et hauteur.
class HiddenRun {
  const HiddenRun({
    required this.id,
    required this.kind,
    required this.wallIndex,
    required this.fromAlongMm,
    required this.fromHeightMm,
    required this.toAlongMm,
    required this.toHeightMm,
  });

  final String id;
  final NetworkKind kind;
  final int wallIndex;
  final int fromAlongMm;
  final int fromHeightMm;
  final int toAlongMm;
  final int toHeightMm;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'wallIndex': wallIndex,
    'from': [fromAlongMm, fromHeightMm],
    'to': [toAlongMm, toHeightMm],
  };

  static HiddenRun fromJson(Map<String, Object?> pJson) {
    final vFrom = (pJson['from']! as List<Object?>).cast<int>();
    final vTo = (pJson['to']! as List<Object?>).cast<int>();

    return HiddenRun(
      id: pJson['id']! as String,
      kind: NetworkKind.values.asNameMap()[pJson['kind']] ?? NetworkKind.electric,
      wallIndex: pJson['wallIndex']! as int,
      fromAlongMm: vFrom[0],
      fromHeightMm: vFrom[1],
      toAlongMm: vTo[0],
      toHeightMm: vTo[1],
    );
  }

  /// Distance d'un point du mur au tracé.
  double distanceTo(int pAlongMm, int pHeightMm) {
    final vDx = (toAlongMm - fromAlongMm).toDouble();
    final vDy = (toHeightMm - fromHeightMm).toDouble();
    final vLength2 = vDx * vDx + vDy * vDy;
    final vShare = vLength2 == 0
        ? 0.0
        : (((pAlongMm - fromAlongMm) * vDx + (pHeightMm - fromHeightMm) * vDy) / vLength2).clamp(
            0.0,
            1.0,
          );
    final vX = fromAlongMm + vDx * vShare - pAlongMm;
    final vY = fromHeightMm + vDy * vShare - pHeightMm;

    return math.sqrt(vX * vX + vY * vY);
  }
}

/// Distance sous laquelle on ne perce pas près d'un réseau relevé.
const drillSafetyMm = 100;

/// Largeur des bandes où la norme fait passer les conduits encastrés : sous le plafond, au-dessus
/// du sol, le long des angles et des huisseries.
const technicalBandMm = 200;

typedef DrillCheck = ({HiddenRun? nearest, int? distanceMm, bool tooClose, bool technicalZone});

/// Peut-on percer au point [pAlongMm], [pHeightMm] du mur [pWallIndex] ?
DrillCheck checkDrill(Room pRoom, int pWallIndex, int pAlongMm, int pHeightMm) {
  HiddenRun? vNearest;
  var vBest = double.infinity;
  for (final vRun in pRoom.networks.where((pRun) => pRun.wallIndex == pWallIndex)) {
    final vDistance = vRun.distanceTo(pAlongMm, pHeightMm);
    if (vDistance < vBest) {
      vBest = vDistance;
      vNearest = vRun;
    }
  }
  final rCheck = (
    nearest: vNearest,
    distanceMm: vNearest == null ? null : vBest.round(),
    tooClose: vBest < drillSafetyMm,
    technicalZone: inTechnicalZone(pRoom, pWallIndex, pAlongMm, pHeightMm),
  );

  return rCheck;
}

/// Le point est-il dans une bande où des conduits passent probablement, même non relevés ?
bool inTechnicalZone(Room pRoom, int pWallIndex, int pAlongMm, int pHeightMm) {
  if (pWallIndex >= pRoom.walls.length) {
    return false;
  }
  final vWall = pRoom.walls[pWallIndex];
  if (pHeightMm > pRoom.ceilingHeightMm - technicalBandMm || pHeightMm < technicalBandMm) {
    return true;
  }
  if (pAlongMm < technicalBandMm || pAlongMm > vWall.lengthMm - technicalBandMm) {
    return true;
  }
  // Le long des montants de portes et fenêtres, et au-dessus d'elles
  for (final vOpening in vWall.openings) {
    final vStart = vOpening.offsetMm;
    final vEnd = vOpening.offsetMm + vOpening.widthMm;
    final vNearSide =
        (pAlongMm - vStart).abs() < technicalBandMm || (pAlongMm - vEnd).abs() < technicalBandMm;
    if (vNearSide) {
      return true;
    }
  }

  return false;
}

/// Longueur totale relevée par type de réseau, en mm.
Map<NetworkKind, int> networkLengths(List<HiddenRun> pRuns) {
  final rLengths = <NetworkKind, int>{};
  for (final vRun in pRuns) {
    final vLength = math
        .sqrt(
          math.pow(vRun.toAlongMm - vRun.fromAlongMm, 2) +
              math.pow(vRun.toHeightMm - vRun.fromHeightMm, 2),
        )
        .round();
    rLengths[vRun.kind] = (rLengths[vRun.kind] ?? 0) + vLength;
  }

  return rLengths;
}
