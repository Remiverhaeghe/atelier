/// Prises et éclairage à placer dans une pièce : minimum courant de la norme NF C 15-100, et
/// propositions de position posées sur le plan.
///
/// Valeurs usuelles d'un logement neuf ou rénové en entier ; elles se vérifient dans la norme à
/// jour ou avec un électricien.
library;

import 'dart:math' as math;

import 'electricity.dart';
import 'fixtures.dart';
import 'geometry.dart';
import 'room.dart';

/// Hauteurs courantes, en mm : axe des prises, prises au-dessus du plan de travail, commandes.
const socketAxisMm = 300;
const worktopSocketAxisMm = 1100;
const switchAxisMm = 1100;

/// Écart laissé de chaque côté d'une porte, et entre la porte et l'interrupteur.
const doorClearanceMm = 150;

/// Écart gardé avec un angle : une prise dans le coin se cache derrière un meuble.
const cornerMarginMm = 200;

/// Une cuisine de 4 m² ou moins se contente de trois prises.
const smallKitchenM2 = 4.0;

/// Type de pièce deviné d'après son nom ; séjour si rien ne correspond.
ElecRoomKind guessElecKind(String pName) {
  final vName = pName.toLowerCase();
  bool vHas(List<String> pWords) => pWords.any(vName.contains);
  final rKind = vHas(['cuisine'])
      ? ElecRoomKind.kitchen
      : vHas(['bain', "salle d'eau", 'douche'])
      ? ElecRoomKind.bathroom
      : vHas(['wc', 'toilette'])
      ? ElecRoomKind.toilet
      : vHas(['chambre', 'bureau'])
      ? ElecRoomKind.bedroom
      : vHas(['couloir', 'entrée', 'dégagement', 'palier'])
      ? ElecRoomKind.hallway
      : ElecRoomKind.living;

  return rKind;
}

/// Prises minimales de la pièce, petite cuisine comprise.
int requiredSockets(ElecRoomKind pKind, double pAreaM2) =>
    pKind == ElecRoomKind.kitchen && pAreaM2 <= smallKitchenM2
    ? 3
    : minSockets(ElecRoom(kind: pKind, areaM2: pAreaM2));

/// Un point lumineux au plafond par pièce au moins.
const requiredLights = 1;

/// Pièce d'eau : les prises restent hors des volumes 0, 1 et 2 autour de la baignoire ou douche.
bool hasWetZones(ElecRoomKind pKind) => pKind == ElecRoomKind.bathroom;

/// Bout de mur où une prise peut aller : mur, début et fin le long du mur.
typedef WallSpan = ({int wall, int fromMm, int toMm});

/// Morceaux de murs libres, hors portes et passages et un peu de place à côté.
List<WallSpan> freeSpans(Room pRoom) {
  final rSpans = <WallSpan>[];
  for (final (vIndex, vWall) in pRoom.walls.indexed) {
    final vDoors = [
      for (final vOpening in vWall.openings)
        if (vOpening.kind != OpeningKind.window) vOpening,
    ]..sort((pA, pB) => pA.offsetMm.compareTo(pB.offsetMm));
    var vStart = 0;
    for (final vDoor in vDoors) {
      final vEnd = vDoor.offsetMm - doorClearanceMm;
      if (vEnd > vStart) {
        rSpans.add((wall: vIndex, fromMm: vStart, toMm: vEnd));
      }
      vStart = math.max(vStart, vDoor.offsetMm + vDoor.widthMm + doorClearanceMm);
    }
    if (vWall.lengthMm > vStart) {
      rSpans.add((wall: vIndex, fromMm: vStart, toMm: vWall.lengthMm));
    }
  }

  return rSpans;
}

/// Point du plan à [pAlongMm] du début du mur [pWall].
PlanPoint pointOnWall(Room pRoom, int pWall, int pAlongMm) {
  final vPoints = outline(pRoom);
  final vStart = vPoints[pWall];
  final vEnd = vPoints[pWall + 1];
  final vShare = pAlongMm / math.max(pRoom.walls[pWall].lengthMm, 1);
  final rPoint = PlanPoint(
    vStart.x + (vEnd.x - vStart.x) * vShare,
    vStart.y + (vEnd.y - vStart.y) * vShare,
  );

  return rPoint;
}

/// [pCount] prises réparties à intervalles égaux sur les murs libres.
List<PlanPoint> spreadSockets(Room pRoom, int pCount) {
  final vSpans = freeSpans(pRoom);
  final vTotal = vSpans.fold(0, (pSum, pSpan) => pSum + pSpan.toMm - pSpan.fromMm);
  if (pCount <= 0 || vTotal <= 0) {
    return const [];
  }
  final rPoints = <PlanPoint>[];
  for (var vIndex = 0; vIndex < pCount; vIndex++) {
    // Au milieu de chaque part : jamais collée à un angle
    var vLeft = (vIndex + 0.5) * vTotal / pCount;
    for (final vSpan in vSpans) {
      final vLength = vSpan.toMm - vSpan.fromMm;
      if (vLeft <= vLength) {
        final vWallLength = pRoom.walls[vSpan.wall].lengthMm;
        final vAlong = vWallLength > 2 * cornerMarginMm
            ? (vSpan.fromMm + vLeft).round().clamp(cornerMarginMm, vWallLength - cornerMarginMm)
            : (vSpan.fromMm + vLeft).round();
        rPoints.add(pointOnWall(pRoom, vSpan.wall, vAlong));
        break;
      }
      vLeft -= vLength;
    }
  }

  return rPoints;
}

/// Centre de gravité du contour : la place habituelle du point lumineux.
PlanPoint ceilingCentre(Room pRoom) {
  final vPoints = outline(pRoom);
  var vArea = 0.0;
  var vX = 0.0;
  var vY = 0.0;
  for (var vIndex = 0; vIndex < vPoints.length - 1; vIndex++) {
    final vA = vPoints[vIndex];
    final vB = vPoints[vIndex + 1];
    final vCross = vA.x * vB.y - vB.x * vA.y;
    vArea += vCross;
    vX += (vA.x + vB.x) * vCross;
    vY += (vA.y + vB.y) * vCross;
  }
  if (vArea.abs() < 1e-6) {
    final vCount = vPoints.length;

    return PlanPoint(
      vPoints.fold(0.0, (pSum, pPoint) => pSum + pPoint.x) / vCount,
      vPoints.fold(0.0, (pSum, pPoint) => pSum + pPoint.y) / vCount,
    );
  }

  return PlanPoint(vX / (3 * vArea), vY / (3 * vArea));
}

/// Interrupteur à côté de la première porte, côté mur libre ; à 30 cm du début du mur 1 sans
/// porte.
PlanPoint switchPlace(Room pRoom) {
  for (final (vIndex, vWall) in pRoom.walls.indexed) {
    for (final vOpening in vWall.openings) {
      if (vOpening.kind == OpeningKind.door) {
        final vAfter = vOpening.offsetMm + vOpening.widthMm + doorClearanceMm;
        final vAlong = vAfter <= vWall.lengthMm
            ? vAfter
            : math.max(0, vOpening.offsetMm - doorClearanceMm);

        return pointOnWall(pRoom, vIndex, vAlong);
      }
    }
  }

  return pointOnWall(pRoom, 0, math.min(300, pRoom.walls.first.lengthMm));
}

typedef ElecProposal = ({
  ElecRoomKind kind,
  int requiredSockets,
  int existingSockets,
  int lights,
  bool hasSwitch,

  /// Prises à ajouter, placées loin de celles déjà posées.
  List<PlanPoint> newSockets,
  PlanPoint light,
  PlanPoint? newSwitch,
});

int _count(Room pRoom, FixtureKind pKind) => pRoom.fixtures
    .where((pFixture) => pFixture.kind == pKind)
    .fold(0, (pSum, pFixture) => pSum + pFixture.count);

double _distance(PlanPoint pA, int pX, int pY) =>
    math.sqrt(math.pow(pA.x - pX, 2) + math.pow(pA.y - pY, 2));

/// Ce qui manque dans la pièce pour le minimum courant, et où le poser ; null sans plan.
ElecProposal? proposeElec(Room pRoom, {ElecRoomKind? pKind}) {
  if (pRoom.walls.length < 3) {
    return null;
  }
  final vKind = pKind ?? guessElecKind(pRoom.name);
  final vRequired = requiredSockets(vKind, floorAreaM2(pRoom));
  final vExisting = _count(pRoom, FixtureKind.socket);
  final vMissing = math.max(0, vRequired - vExisting);
  // Parmi les places réparties, celles qui sont le plus loin des prises déjà posées
  final vSockets = [
    for (final vFixture in pRoom.fixtures)
      if (vFixture.kind == FixtureKind.socket) vFixture,
  ];
  double vFarness(PlanPoint pPoint) => vSockets.isEmpty
      ? 0
      : vSockets.map((pFixture) => _distance(pPoint, pFixture.xMm, pFixture.yMm)).reduce(math.min);
  final vCandidates = spreadSockets(pRoom, vRequired)
    ..sort((pA, pB) => vFarness(pB).compareTo(vFarness(pA)));
  final vSwitch = _count(pRoom, FixtureKind.lightSwitch) > 0;
  final rProposal = (
    kind: vKind,
    requiredSockets: vRequired,
    existingSockets: vExisting,
    lights: requiredLights,
    hasSwitch: vSwitch,
    newSockets: vCandidates.take(vMissing).toList(),
    light: ceilingCentre(pRoom),
    newSwitch: vSwitch ? null : switchPlace(pRoom),
  );

  return rProposal;
}

/// Pièce avec les prises et l'interrupteur proposés posés sur son plan.
Room withProposal(Room pRoom, ElecProposal pProposal, {required String Function() pNewId}) {
  final rRoom = pRoom.copyWith(
    fixtures: [
      ...pRoom.fixtures,
      for (final vPoint in pProposal.newSockets)
        Fixture(
          id: pNewId(),
          kind: FixtureKind.socket,
          xMm: vPoint.x.round(),
          yMm: vPoint.y.round(),
        ),
      if (pProposal.newSwitch case final vPoint?)
        Fixture(
          id: pNewId(),
          kind: FixtureKind.lightSwitch,
          xMm: vPoint.x.round(),
          yMm: vPoint.y.round(),
        ),
    ],
  );

  return rRoom;
}
