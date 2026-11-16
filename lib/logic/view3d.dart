/// Vue 3D de la maison : murs extrudés à la hauteur sous plafond, projetés et triés pour le dessin.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'house.dart';
import 'room.dart';

/// Point en 3D, en millimètres : x et y au sol, z vers le haut.
typedef Point3 = ({double x, double y, double z});

/// Face à dessiner : ses coins en 3D, sa profondeur après rotation, et ce qu'elle représente.
typedef Face = ({List<Point3> corners, double depth, FaceKind kind});

enum FaceKind { floor, wall, door, window }

/// Faces de la maison vue sous l'angle [pYawDeg] : sols d'abord, puis murs du fond vers l'avant.
List<Face> houseFaces(List<Room> pRooms, double pYawDeg) {
  final vAll = [for (final vRoom in pRooms) ...houseOutline(vRoom)];
  if (vAll.isEmpty) {
    return const [];
  }
  final vCx = vAll.map((pPoint) => pPoint.x).reduce((pA, pB) => pA + pB) / vAll.length;
  final vCy = vAll.map((pPoint) => pPoint.y).reduce((pA, pB) => pA + pB) / vAll.length;
  final vYaw = pYawDeg * math.pi / 180;
  // Profondeur : distance vers le fond une fois la maison tournée
  double vDepth(List<Point3> pCorners) =>
      pCorners
          .map((pCorner) => (pCorner.x - vCx) * math.sin(vYaw) + (pCorner.y - vCy) * math.cos(vYaw))
          .reduce((pA, pB) => pA + pB) /
      pCorners.length;
  // Faces rangées par niveau : on dessine du bas vers le haut, chaque étage cachant le précédent
  final vFloors = <int, List<Face>>{};
  final vWalls = <int, List<Face>>{};
  for (final vRoom in pRooms) {
    final vPoints = houseOutline(vRoom);
    // Chaque niveau posé sur celui du dessous
    final vLevelBase = levelBaseMm(pRooms, vRoom.level);
    final vBase = vLevelBase.toDouble();
    final vRoomFloors = vFloors.putIfAbsent(vLevelBase, () => []);
    final vRoomWalls = vWalls.putIfAbsent(vLevelBase, () => []);
    final vHeight = vBase + vRoom.ceilingHeightMm;
    final vFloor = [
      for (final vPoint in vPoints.take(vRoom.walls.length)) (x: vPoint.x, y: vPoint.y, z: vBase),
    ];
    vRoomFloors.add((corners: vFloor, depth: vDepth(vFloor), kind: FaceKind.floor));
    for (var vIndex = 0; vIndex < vRoom.walls.length; vIndex++) {
      final vStart = vPoints[vIndex];
      final vEnd = vPoints[vIndex + 1];
      final vWall = _quad(vStart, vEnd, vBase, vHeight);
      vRoomWalls.add((corners: vWall, depth: vDepth(vWall), kind: FaceKind.wall));
      final vLength = vRoom.walls[vIndex].lengthMm.toDouble();
      for (final vOpening in vRoom.walls[vIndex].openings) {
        if (vLength <= 0) {
          continue;
        }
        PlanPoint vAlong(double pMm) => PlanPoint(
          vStart.x + (vEnd.x - vStart.x) * pMm / vLength,
          vStart.y + (vEnd.y - vStart.y) * pMm / vLength,
        );
        final vQuad = _quad(
          vAlong(vOpening.offsetMm.toDouble()),
          vAlong((vOpening.offsetMm + vOpening.widthMm).toDouble()),
          vBase + vOpening.sill,
          math.min(vBase + vOpening.sill + vOpening.height, vHeight),
        );
        // Un peu devant le mur, pour être dessinée juste après lui
        vRoomWalls.add((
          corners: vQuad,
          depth: vDepth(vQuad) - 1,
          kind: vOpening.kind == OpeningKind.window ? FaceKind.window : FaceKind.door,
        ));
      }
    }
  }
  final rFaces = <Face>[];
  for (final vBase in vFloors.keys.toList()..sort()) {
    rFaces
      ..addAll(vFloors[vBase]!)
      ..addAll(vWalls[vBase]!..sort((pA, pB) => pB.depth.compareTo(pA.depth)));
  }

  return rFaces;
}

List<Point3> _quad(PlanPoint pStart, PlanPoint pEnd, double pBottom, double pTop) => [
  (x: pStart.x, y: pStart.y, z: pBottom),
  (x: pEnd.x, y: pEnd.y, z: pBottom),
  (x: pEnd.x, y: pEnd.y, z: pTop),
  (x: pStart.x, y: pStart.y, z: pTop),
];

/// Projection vue d'en haut et de biais : rotation autour du centre, inclinaison de [pPitchDeg].
({double x, double y}) project(Point3 pPoint, double pYawDeg, {double pPitchDeg = 35}) {
  final vYaw = pYawDeg * math.pi / 180;
  final vPitch = pPitchDeg * math.pi / 180;
  final vX = pPoint.x * math.cos(vYaw) - pPoint.y * math.sin(vYaw);
  final vY = pPoint.x * math.sin(vYaw) + pPoint.y * math.cos(vYaw);

  return (x: vX, y: -vY * math.sin(vPitch) - pPoint.z * math.cos(vPitch));
}
