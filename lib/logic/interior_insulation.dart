/// Isolation des murs par l'intérieur : isolant selon la résistance visée, ossature, pare-vapeur,
/// plaques et surface habitable perdue, pièce par pièce.
library;

import 'geometry.dart';
import 'insulation.dart';
import 'room.dart';

/// Façon de poser l'isolant contre le mur.
enum LiningSystem {
  /// Isolant derrière des fourrures métalliques tenues par des appuis, puis plaque.
  metalFrame(18, 13),

  /// Complexe isolant et plaque collé au mur par plots de mortier adhésif.
  gluedComplex(10, 10),

  /// Ossature bois de la même épaisseur que l'isolant, puis plaque.
  timberFrame(0, 13);

  const LiningSystem(this.gapMm, this.boardMm);

  /// Épaisseur ajoutée par l'ossature ou la colle, en plus de l'isolant.
  final int gapMm;
  final int boardMm;

  bool get hasFrame => this != gluedComplex;
}

/// Écartement des montants ou fourrures, et des appuis sur la hauteur.
const studSpacingMm = 600;
const bracketSpacingMm = 1350;

/// Plaque de plâtre courante : 120 × 250 cm, et marge de coupe.
const liningBoardM2 = 3.0;
const liningWastePercent = 10;

/// Mortier adhésif d'un doublage collé : environ 3,5 kg par m², sacs de 25 kg (indicatif).
const adhesiveKgPerM2 = 3.5;
const adhesiveBagKg = 25;

/// Les isolants fibreux laissent passer la vapeur d'eau : un pare-vapeur côté pièce les protège.
bool needsVaporBarrier(Insulant pInsulant) => pInsulant != Insulant.polyurethane;

/// Murs isolés d'une pièce, par numéro (index dans la liste des murs).
typedef RoomLining = ({Room room, Set<int> walls});

typedef RoomLoss = ({
  Room room,
  double wallM2,
  double lostM2,
  double floorBeforeM2,
  int windows,
  int studs,
});

/// Épaisseur totale prise sur la pièce : isolant, ossature ou colle, plaque.
int liningDepthMm(List<int> pLayersMm, LiningSystem pSystem) =>
    pLayersMm.fold(0, (pSum, pLayer) => pSum + pLayer) + pSystem.gapMm + pSystem.boardMm;

/// Surface au sol perdue quand on double les murs [pWalls] de [pDepthMm] : une bande le long de
/// chaque mur, moins le carré compté deux fois dans un coin rentrant, plus le carré ajouté dans un
/// coin sortant.
double lostFloorM2(Room pRoom, Set<int> pWalls, int pDepthMm) {
  final vCount = pRoom.walls.length;
  var vLost = 0.0;
  for (final vIndex in pWalls.where((pIndex) => pIndex < vCount)) {
    vLost += pRoom.walls[vIndex].lengthMm * pDepthMm;
    final vNext = (vIndex + 1) % vCount;
    final vCorner = pRoom.closed || vIndex + 1 < vCount;
    if (vCorner && vNext != vIndex && pWalls.contains(vNext)) {
      final vSquare = (pDepthMm * pDepthMm).toDouble();
      vLost += pRoom.walls[vIndex].angleToNextDeg > 180 ? vSquare : -vSquare;
    }
  }

  return vLost / 1e6;
}

/// Pan de mur isolé, ouvertures déduites, en m².
double liningWallM2(Room pRoom, int pWallIndex) {
  final vWall = pRoom.walls[pWallIndex];
  final vOpenings = vWall.openings.fold(
    0.0,
    (pSum, pOpening) => pSum + pOpening.widthMm * pOpening.height,
  );
  final rArea = (vWall.lengthMm * pRoom.ceilingHeightMm - vOpenings) / 1e6;

  return rArea < 0 ? 0 : rArea;
}

typedef LiningPlan = ({
  List<int> layersMm,
  double achievedR,
  int depthMm,
  double wallM2,
  double lostM2,
  int insulantPacks,
  double vaporBarrierM2,
  int boards,
  int studs,
  int railsMetres,
  int brackets,
  int adhesiveBags,
  List<RoomLoss> rooms,
});

/// Plan d'isolation pour toutes les pièces choisies, avec la perte de surface de chacune.
LiningPlan planLining({
  required List<RoomLining> pRooms,
  required Insulant pInsulant,
  required LiningSystem pSystem,
  double? pTargetR,
  double pPackM2 = 5,
}) {
  final vRoomLosses = <RoomLoss>[];
  var vWallM2 = 0.0;
  var vStuds = 0;
  var vRailsMm = 0;
  var vBrackets = 0;
  // L'isolant est le même partout : l'épaisseur ne dépend pas de la surface
  final vLayers = planInsulation(
    pPart: InsulatedPart.walls,
    pInsulant: pInsulant,
    pAreaM2: 1,
    pTargetR: pTargetR,
  );
  final vDepth = liningDepthMm(vLayers.layersMm, pSystem);
  for (final vLining in pRooms) {
    final vRoom = vLining.room;
    final vWalls = {
      for (final vIndex in vLining.walls)
        if (vIndex < vRoom.walls.length) vIndex,
    };
    if (vWalls.isEmpty) {
      continue;
    }
    var vRoomWall = 0.0;
    var vRoomStuds = 0;
    var vWindows = 0;
    for (final vIndex in vWalls) {
      final vLength = vRoom.walls[vIndex].lengthMm;
      vRoomWall += liningWallM2(vRoom, vIndex);
      if (pSystem.hasFrame) {
        final vWallStuds = (vLength / studSpacingMm - 1e-9).ceil() + 1;
        vRoomStuds += vWallStuds;
        // Rail au sol et au plafond
        vRailsMm += 2 * vLength;
        if (pSystem == LiningSystem.metalFrame) {
          vBrackets += vWallStuds * (vRoom.ceilingHeightMm / bracketSpacingMm - 1e-9).ceil();
        }
      }
      vWindows += vRoom.walls[vIndex].openings
          .where((pOpening) => pOpening.kind == OpeningKind.window)
          .length;
    }
    vWallM2 += vRoomWall;
    vStuds += vRoomStuds;
    vRoomLosses.add((
      room: vRoom,
      wallM2: vRoomWall,
      lostM2: lostFloorM2(vRoom, vWalls, vDepth),
      floorBeforeM2: floorAreaM2(vRoom),
      windows: vWindows,
      studs: vRoomStuds,
    ));
  }
  final vInsulation = planInsulation(
    pPart: InsulatedPart.walls,
    pInsulant: pInsulant,
    pAreaM2: vWallM2,
    pPackM2: pPackM2,
    pTargetR: pTargetR,
  );
  final vWithWaste = vWallM2 * (1 + liningWastePercent / 100);
  final rPlan = (
    layersMm: vInsulation.layersMm,
    achievedR: vInsulation.achievedR,
    depthMm: vDepth,
    wallM2: vWallM2,
    lostM2: vRoomLosses.fold(0.0, (pSum, pRoom) => pSum + pRoom.lostM2),
    insulantPacks: vInsulation.packs,
    vaporBarrierM2: needsVaporBarrier(pInsulant) ? vInsulation.vaporBarrierM2 : 0.0,
    boards: vWallM2 == 0 ? 0 : (vWithWaste / liningBoardM2 - 1e-9).ceil(),
    studs: vStuds,
    railsMetres: (vRailsMm / 1000 - 1e-9).ceil(),
    brackets: vBrackets,
    adhesiveBags: pSystem == LiningSystem.gluedComplex && vWallM2 > 0
        ? (vWallM2 * adhesiveKgPerM2 / adhesiveBagKg - 1e-9).ceil()
        : 0,
    rooms: vRoomLosses,
  );

  return rPlan;
}
