/// Électricité depuis le plan : circuits, gaines, fils et boîtes d'après les prises et
/// interrupteurs posés sur le plan des pièces.
library;

import 'dart:math' as math;

import 'fixtures.dart';
import 'room.dart';

/// Points par circuit : prises en 2,5 mm² sur 20 A, éclairage en 1,5 mm² sur 16 A.
const socketsPerCircuit = 12;
const lightsPerCircuit = 8;

/// Gaine pour descendre ou monter dans la cloison jusqu'à la boîte, et réserve dans la boîte.
const dropPerBoxMm = 1200;
const wireSpareMm = 300;

typedef ElecRun = ({int boxes, int sheathMm});

/// Points d'un type dans la pièce, reliés de proche en proche, plus la descente de chaque boîte.
ElecRun _run(Room pRoom, FixtureKind pKind) {
  final vPoints = [
    for (final vFixture in pRoom.fixtures)
      if (vFixture.kind == pKind) vFixture,
  ];
  if (vPoints.isEmpty) {
    return (boxes: 0, sheathMm: 0);
  }
  // Chemin de proche en proche depuis le premier point posé
  final vLeft = [...vPoints.skip(1)];
  var vCurrent = vPoints.first;
  var vLength = 0.0;
  while (vLeft.isNotEmpty) {
    vLeft.sort((pA, pB) => _distance(vCurrent, pA).compareTo(_distance(vCurrent, pB)));
    final vNext = vLeft.removeAt(0);
    vLength += _distance(vCurrent, vNext);
    vCurrent = vNext;
  }
  final vBoxes = vPoints.fold(0, (pSum, pFixture) => pSum + pFixture.count);
  final rRun = (boxes: vBoxes, sheathMm: (vLength + vPoints.length * dropPerBoxMm).round());

  return rRun;
}

double _distance(Fixture pA, Fixture pB) =>
    math.sqrt(math.pow(pA.xMm - pB.xMm, 2) + math.pow(pA.yMm - pB.yMm, 2));

typedef ElecPlan = ({
  int sockets,
  int lights,
  int socketCircuits,
  int lightCircuits,
  int sheath20Mm,
  int sheath16Mm,
  int wire25Mm,
  int wire15Mm,
  int boxes,
});

/// Bilan de la maison d'après les plans ; la liaison au tableau n'est pas comptée.
ElecPlan elecPlan(List<Room> pRooms) {
  var vSockets = 0;
  var vLights = 0;
  var vSheath20 = 0;
  var vSheath16 = 0;
  for (final vRoom in pRooms) {
    final vSocketRun = _run(vRoom, FixtureKind.socket);
    final vLightRun = _run(vRoom, FixtureKind.lightSwitch);
    vSockets += vSocketRun.boxes;
    vLights += vLightRun.boxes;
    vSheath20 += vSocketRun.sheathMm;
    vSheath16 += vLightRun.sheathMm;
  }
  int vCircuits(int pPoints, int pPerCircuit) => pPoints == 0 ? 0 : (pPoints / pPerCircuit).ceil();
  // Trois fils par gaine (phase, neutre, terre), plus la réserve de chaque boîte
  final rPlan = (
    sockets: vSockets,
    lights: vLights,
    socketCircuits: vCircuits(vSockets, socketsPerCircuit),
    lightCircuits: vCircuits(vLights, lightsPerCircuit),
    sheath20Mm: vSheath20,
    sheath16Mm: vSheath16,
    wire25Mm: 3 * vSheath20 + vSockets * wireSpareMm,
    wire15Mm: 3 * vSheath16 + vLights * wireSpareMm,
    boxes: vSockets + vLights,
  );

  return rPlan;
}
