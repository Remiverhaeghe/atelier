/// Meubles sur le plan : place, débattement des portes et passages, vérifiés avant l'achat.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Meubles courants, avec leur taille habituelle (largeur × profondeur).
enum FurnitureKind {
  doubleBed(1400, 1900),
  singleBed(900, 1900),
  sofa(2200, 900),
  table(1600, 900),
  desk(1200, 600),
  wardrobe(1000, 600),
  chest(800, 450),
  sideboard(1800, 450),
  other(1000, 500);

  const FurnitureKind(this.widthMm, this.depthMm);

  final int widthMm;
  final int depthMm;
}

/// Passage confortable entre deux meubles ou un meuble et un mur.
const minPassageMm = 600;

/// Écart sous lequel un meuble est considéré contre le mur, pas devant un passage.
const againstWallMm = 50;

class Furniture {
  const Furniture({
    required this.id,
    required this.kind,
    required this.xMm,
    required this.yMm,
    required this.widthMm,
    required this.depthMm,
    this.turned = false,
  });

  final String id;
  final FurnitureKind kind;

  /// Centre du meuble dans le repère de la pièce.
  final int xMm;
  final int yMm;
  final int widthMm;
  final int depthMm;

  /// Tourné d'un quart de tour : la largeur suit l'axe y.
  final bool turned;

  Furniture copyWith({int? xMm, int? yMm, int? widthMm, int? depthMm, bool? turned}) => Furniture(
    id: id,
    kind: kind,
    xMm: xMm ?? this.xMm,
    yMm: yMm ?? this.yMm,
    widthMm: widthMm ?? this.widthMm,
    depthMm: depthMm ?? this.depthMm,
    turned: turned ?? this.turned,
  );

  /// Coins du meuble, dans le sens inverse des aiguilles d'une montre.
  List<PlanPoint> get corners {
    final vHalfX = (turned ? depthMm : widthMm) / 2;
    final vHalfY = (turned ? widthMm : depthMm) / 2;

    return [
      PlanPoint(xMm - vHalfX, yMm - vHalfY),
      PlanPoint(xMm + vHalfX, yMm - vHalfY),
      PlanPoint(xMm + vHalfX, yMm + vHalfY),
      PlanPoint(xMm - vHalfX, yMm + vHalfY),
    ];
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'xMm': xMm,
    'yMm': yMm,
    'widthMm': widthMm,
    'depthMm': depthMm,
    if (turned) 'turned': true,
  };

  static Furniture fromJson(Map<String, Object?> pJson) => Furniture(
    id: pJson['id']! as String,
    kind: FurnitureKind.values.asNameMap()[pJson['kind']] ?? FurnitureKind.other,
    xMm: pJson['xMm']! as int,
    yMm: pJson['yMm']! as int,
    widthMm: pJson['widthMm']! as int,
    depthMm: pJson['depthMm']! as int,
    turned: (pJson['turned'] as bool?) ?? false,
  );
}

/// Problème relevé sur un meuble.
enum FurnitureIssueKind { outside, overlap, door, passage }

typedef FurnitureIssue = ({FurnitureIssueKind kind, String furnitureId, int? wallIndex, int? gapMm, String? otherId});

/// Deux polygones convexes se chevauchent-ils ? Théorème de l'axe séparateur.
bool _overlap(List<PlanPoint> pA, List<PlanPoint> pB) {
  for (final vPolygon in [pA, pB]) {
    for (var vIndex = 0; vIndex < vPolygon.length; vIndex++) {
      final vP = vPolygon[vIndex];
      final vQ = vPolygon[(vIndex + 1) % vPolygon.length];
      final vAxisX = -(vQ.y - vP.y);
      final vAxisY = vQ.x - vP.x;
      double vProject(PlanPoint pPoint) => pPoint.x * vAxisX + pPoint.y * vAxisY;
      final vA = pA.map(vProject);
      final vB = pB.map(vProject);
      // Contact sans recouvrement : pas un chevauchement
      if (vA.reduce(math.max) <= vB.reduce(math.min) + 1e-6 ||
          vB.reduce(math.max) <= vA.reduce(math.min) + 1e-6) {
        return false;
      }
    }
  }

  return true;
}

double _pointToSegment(PlanPoint pPoint, PlanPoint pA, PlanPoint pB) {
  final vDx = pB.x - pA.x;
  final vDy = pB.y - pA.y;
  final vLength2 = vDx * vDx + vDy * vDy;
  final vShare = vLength2 == 0
      ? 0.0
      : (((pPoint.x - pA.x) * vDx + (pPoint.y - pA.y) * vDy) / vLength2).clamp(0.0, 1.0);

  return pPoint.distanceTo(PlanPoint(pA.x + vDx * vShare, pA.y + vDy * vShare));
}

/// Plus petite distance entre deux polygones qui ne se touchent pas.
double _gap(List<PlanPoint> pA, List<PlanPoint> pB) {
  var rGap = double.infinity;
  for (final (vFrom, vTo) in [(pA, pB), (pB, pA)]) {
    for (final vPoint in vFrom) {
      for (var vIndex = 0; vIndex < vTo.length; vIndex++) {
        rGap = math.min(rGap, _pointToSegment(vPoint, vTo[vIndex], vTo[(vIndex + 1) % vTo.length]));
      }
    }
  }

  return rGap;
}

bool _inside(List<PlanPoint> pPolygon, PlanPoint pPoint) {
  var vInside = false;
  for (var vIndex = 0, vPrev = pPolygon.length - 1; vIndex < pPolygon.length; vPrev = vIndex++) {
    final vA = pPolygon[vIndex];
    final vB = pPolygon[vPrev];
    if ((vA.y > pPoint.y) != (vB.y > pPoint.y) &&
        pPoint.x < (vB.x - vA.x) * (pPoint.y - vA.y) / (vB.y - vA.y) + vA.x) {
      vInside = !vInside;
    }
  }

  return vInside;
}

/// Zone balayée par une porte : un carré de sa largeur, côté pièce.
List<PlanPoint> doorSweep(Room pRoom, int pWallIndex, Opening pDoor) {
  final vPoints = outline(pRoom);
  final vStart = vPoints[pWallIndex];
  final vEnd = vPoints[pWallIndex + 1];
  final vLength = math.max(vStart.distanceTo(vEnd), 1);
  final vDirX = (vEnd.x - vStart.x) / vLength;
  final vDirY = (vEnd.y - vStart.y) / vLength;
  // Murs dans le sens inverse des aiguilles d'une montre : l'intérieur est à gauche
  PlanPoint vAt(double pAlong, double pInside) => PlanPoint(
    vStart.x + vDirX * pAlong - vDirY * pInside,
    vStart.y + vDirY * pAlong + vDirX * pInside,
  );
  final vFrom = pDoor.offsetMm.toDouble();
  final vTo = (pDoor.offsetMm + pDoor.widthMm).toDouble();
  final vDepth = pDoor.widthMm.toDouble();

  return [vAt(vFrom, 0), vAt(vTo, 0), vAt(vTo, vDepth), vAt(vFrom, vDepth)];
}

/// Problèmes de chaque meuble : hors de la pièce, sur un autre meuble, dans le débattement
/// d'une porte, ou passage de moins de 60 cm.
List<FurnitureIssue> furnitureIssues(Room pRoom) {
  final rIssues = <FurnitureIssue>[];
  if (pRoom.walls.length < 3) {
    return rIssues;
  }
  final vOutline = outline(pRoom).take(pRoom.walls.length).toList();
  final vItems = pRoom.furniture;
  for (var vIndex = 0; vIndex < vItems.length; vIndex++) {
    final vItem = vItems[vIndex];
    final vCorners = vItem.corners;
    if (!vCorners.every((pCorner) => _inside(vOutline, pCorner))) {
      rIssues.add((kind: FurnitureIssueKind.outside, furnitureId: vItem.id, wallIndex: null, gapMm: null, otherId: null));
      continue;
    }
    for (var vWall = 0; vWall < pRoom.walls.length; vWall++) {
      for (final vDoor in pRoom.walls[vWall].openings.where((pOpening) => pOpening.kind == OpeningKind.door)) {
        if (_overlap(vCorners, doorSweep(pRoom, vWall, vDoor))) {
          rIssues.add((kind: FurnitureIssueKind.door, furnitureId: vItem.id, wallIndex: vWall, gapMm: null, otherId: null));
        }
      }
      final vGap = _gap(vCorners, [vOutline[vWall], vOutline[(vWall + 1) % vOutline.length]]);
      if (vGap > againstWallMm && vGap < minPassageMm) {
        rIssues.add((kind: FurnitureIssueKind.passage, furnitureId: vItem.id, wallIndex: vWall, gapMm: vGap.round(), otherId: null));
      }
    }
    for (final vOther in vItems.skip(vIndex + 1)) {
      if (_overlap(vCorners, vOther.corners)) {
        rIssues.add((kind: FurnitureIssueKind.overlap, furnitureId: vItem.id, wallIndex: null, gapMm: null, otherId: vOther.id));
      } else {
        final vGap = _gap(vCorners, vOther.corners);
        if (vGap > againstWallMm && vGap < minPassageMm) {
          rIssues.add((kind: FurnitureIssueKind.passage, furnitureId: vItem.id, wallIndex: null, gapMm: vGap.round(), otherId: vOther.id));
        }
      }
    }
  }

  return rIssues;
}
