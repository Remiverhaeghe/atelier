/// Export de la maison en glTF 2.0 (fichier .gltf autonome), lisible par Blender ou un visualiseur web.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'room.dart';
import 'view3d.dart';

/// Triangles d'un polygone plan par la méthode des oreilles ; indices dans [pPoints].
///
/// Une pièce en L n'est pas convexe : un simple éventail depuis un sommet déborderait.
List<int> triangulate(List<({double x, double y})> pPoints) {
  final vCount = pPoints.length;
  if (vCount < 3) {
    return const [];
  }
  var vTwiceArea = 0.0;
  for (var vIndex = 0; vIndex < vCount; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % vCount];
    vTwiceArea += vA.x * vB.y - vB.x * vA.y;
  }
  final vRemaining = vTwiceArea >= 0
      ? List.generate(vCount, (pIndex) => pIndex)
      : List.generate(vCount, (pIndex) => vCount - 1 - pIndex);
  double vCross(({double x, double y}) pA, ({double x, double y}) pB, ({double x, double y}) pC) =>
      (pB.x - pA.x) * (pC.y - pA.y) - (pB.y - pA.y) * (pC.x - pA.x);
  final rTriangles = <int>[];
  var vGuard = 0;
  while (vRemaining.length > 3 && vGuard < vCount * vCount) {
    vGuard++;
    var vFound = false;
    for (var vIndex = 0; vIndex < vRemaining.length; vIndex++) {
      final vPrevious = vRemaining[(vIndex - 1 + vRemaining.length) % vRemaining.length];
      final vCurrent = vRemaining[vIndex];
      final vNext = vRemaining[(vIndex + 1) % vRemaining.length];
      final vA = pPoints[vPrevious];
      final vB = pPoints[vCurrent];
      final vC = pPoints[vNext];
      if (vCross(vA, vB, vC) <= 0) {
        continue;
      }
      final vBlocked = vRemaining.any((pOther) {
        if (pOther == vPrevious || pOther == vCurrent || pOther == vNext) {
          return false;
        }
        final vP = pPoints[pOther];
        return vCross(vA, vB, vP) >= 0 && vCross(vB, vC, vP) >= 0 && vCross(vC, vA, vP) >= 0;
      });
      if (vBlocked) {
        continue;
      }
      rTriangles.addAll([vPrevious, vCurrent, vNext]);
      vRemaining.removeAt(vIndex);
      vFound = true;
      break;
    }
    if (!vFound) {
      break;
    }
  }
  // Reste : le dernier triangle, ou un éventail si le contour était dégénéré
  for (var vIndex = 1; vIndex < vRemaining.length - 1; vIndex++) {
    rTriangles.addAll([vRemaining[0], vRemaining[vIndex], vRemaining[vIndex + 1]]);
  }

  return rTriangles;
}

/// Couleur de chaque sorte de face : parquet, murs clairs, portes en bois, vitres bleutées, meubles.
const _colors = {
  FaceKind.floor: [0.78, 0.6, 0.38, 1.0],
  FaceKind.wall: [0.93, 0.93, 0.9, 1.0],
  FaceKind.door: [0.55, 0.38, 0.22, 1.0],
  FaceKind.window: [0.55, 0.75, 0.9, 1.0],
  FaceKind.furniture: [0.68, 0.52, 0.36, 1.0],
};

/// Fichier glTF de la maison, en mètres, axe vertical Y comme le veut le format.
Map<String, Object?> buildGltf(List<Room> pRooms) {
  final vFaces = houseFaces(pRooms, 0);
  final vBytes = BytesBuilder();
  final vViews = <Map<String, Object?>>[];
  final vAccessors = <Map<String, Object?>>[];
  final vMeshes = <Map<String, Object?>>[];
  final vMaterials = <Map<String, Object?>>[];
  for (final vKind in FaceKind.values) {
    final vPositions = <double>[];
    final vIndices = <int>[];
    for (final vFace in vFaces.where((pFace) => pFace.kind == vKind)) {
      final vBase = vPositions.length ~/ 3;
      for (final vCorner in vFace.corners) {
        // Plan en millimètres, y vers le nord ; glTF en mètres, Y vers le haut, Z vers le sud
        vPositions.addAll([vCorner.x / 1000, vCorner.z / 1000, -vCorner.y / 1000]);
      }
      final vLocal = vKind == FaceKind.floor
          ? triangulate([for (final vCorner in vFace.corners) (x: vCorner.x, y: vCorner.y)])
          : const [0, 1, 2, 0, 2, 3];
      vIndices.addAll(vLocal.map((pIndex) => vBase + pIndex));
    }
    if (vIndices.isEmpty) {
      continue;
    }
    final vPositionView = vViews.length;
    final vPositionBytes = Float32List.fromList(vPositions).buffer.asUint8List();
    vViews.add({
      'buffer': 0,
      'byteOffset': vBytes.length,
      'byteLength': vPositionBytes.length,
      'target': 34962,
    });
    vBytes.add(vPositionBytes);
    final vIndexBytes = Uint32List.fromList(vIndices).buffer.asUint8List();
    vViews.add({
      'buffer': 0,
      'byteOffset': vBytes.length,
      'byteLength': vIndexBytes.length,
      'target': 34963,
    });
    vBytes.add(vIndexBytes);
    List<double> vBound(bool pMax) => [
      for (var vAxis = 0; vAxis < 3; vAxis++)
        [
          for (var vIndex = vAxis; vIndex < vPositions.length; vIndex += 3) vPositions[vIndex],
        ].reduce((pA, pB) => (pA > pB) == pMax ? pA : pB),
    ];
    vAccessors
      ..add({
        'bufferView': vPositionView,
        'componentType': 5126,
        'count': vPositions.length ~/ 3,
        'type': 'VEC3',
        'min': vBound(false),
        'max': vBound(true),
      })
      ..add({
        'bufferView': vPositionView + 1,
        'componentType': 5125,
        'count': vIndices.length,
        'type': 'SCALAR',
      });
    vMaterials.add({
      'name': vKind.name,
      'pbrMetallicRoughness': {
        'baseColorFactor': _colors[vKind],
        'metallicFactor': 0.0,
        'roughnessFactor': 0.9,
      },
      // Les murs se voient des deux côtés, de l'intérieur comme de l'extérieur
      'doubleSided': true,
    });
    vMeshes.add({
      'name': vKind.name,
      'primitives': [
        {
          'attributes': {'POSITION': vAccessors.length - 2},
          'indices': vAccessors.length - 1,
          'material': vMaterials.length - 1,
        },
      ],
    });
  }
  final vBuffer = vBytes.takeBytes();
  final rGltf = {
    'asset': {'version': '2.0', 'generator': 'Atelier'},
    'scene': 0,
    'scenes': [
      {
        'nodes': [for (var vIndex = 0; vIndex < vMeshes.length; vIndex++) vIndex],
      },
    ],
    'nodes': [
      for (var vIndex = 0; vIndex < vMeshes.length; vIndex++)
        {'mesh': vIndex, 'name': vMeshes[vIndex]['name']},
    ],
    'meshes': vMeshes,
    'materials': vMaterials,
    'accessors': vAccessors,
    'bufferViews': vViews,
    'buffers': [
      {
        'byteLength': vBuffer.length,
        'uri': 'data:application/octet-stream;base64,${base64Encode(vBuffer)}',
      },
    ],
  };

  return rGltf;
}
