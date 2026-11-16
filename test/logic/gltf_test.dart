import 'dart:convert';

import 'package:atelier/logic/gltf.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Surface couverte par des triangles, pour vérifier qu'ils pavent bien le polygone.
double trianglesArea(List<({double x, double y})> pPoints, List<int> pTriangles) {
  var rArea = 0.0;
  for (var vIndex = 0; vIndex < pTriangles.length; vIndex += 3) {
    final vA = pPoints[pTriangles[vIndex]];
    final vB = pPoints[pTriangles[vIndex + 1]];
    final vC = pPoints[pTriangles[vIndex + 2]];
    rArea += ((vB.x - vA.x) * (vC.y - vA.y) - (vB.y - vA.y) * (vC.x - vA.x)).abs() / 2;
  }

  return rArea;
}

void main() {
  test('rectangle en deux triangles, pièce en L sans déborder', () {
    const vSquare = [(x: 0.0, y: 0.0), (x: 4.0, y: 0.0), (x: 4.0, y: 3.0), (x: 0.0, y: 3.0)];
    expect(triangulate(vSquare), hasLength(6));
    expect(trianglesArea(vSquare, triangulate(vSquare)), 12);

    const vL = [
      (x: 0.0, y: 0.0),
      (x: 5.0, y: 0.0),
      (x: 5.0, y: 2.0),
      (x: 3.0, y: 2.0),
      (x: 3.0, y: 4.0),
      (x: 0.0, y: 4.0),
    ];
    expect(triangulate(vL), hasLength(12));
    expect(trianglesArea(vL, triangulate(vL)), 16);
    // Même contour parcouru dans l'autre sens
    expect(trianglesArea(vL.reversed.toList(), triangulate(vL.reversed.toList())), 16);
    expect(triangulate(const [(x: 0.0, y: 0.0), (x: 1.0, y: 0.0)]), isEmpty);
  });

  test('glTF de la maison : sol, murs, porte, tampon cohérent', () {
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(lengthMm: 4000, openings: [Opening(kind: OpeningKind.door, offsetMm: 500, widthMm: 830)]),
        ...rectangleRoom().walls.skip(1),
      ],
    );
    final vGltf = jsonDecode(jsonEncode(buildGltf([vRoom]))) as Map<String, Object?>;

    expect((vGltf['asset']! as Map)['version'], '2.0');
    final vMeshes = [for (final vMesh in vGltf['meshes']! as List) (vMesh as Map)['name']];
    expect(vMeshes, ['floor', 'wall', 'door']);
    final vBuffer = (vGltf['buffers']! as List).single as Map;
    final vData = base64Decode((vBuffer['uri']! as String).split(',').last);
    expect(vData.length, vBuffer['byteLength']);
    final vViews = vGltf['bufferViews']! as List;
    final vLast = vViews.last as Map;
    expect((vLast['byteOffset']! as int) + (vLast['byteLength']! as int), vData.length);

    final vAccessors = [for (final vAccessor in vGltf['accessors']! as List) vAccessor as Map];
    // Sol : 4 sommets, 2 triangles ; murs : 4 quadrilatères
    expect(vAccessors[0]['count'], 4);
    expect(vAccessors[1]['count'], 6);
    expect(vAccessors[2]['count'], 16);
    // Hauteur sous plafond de 2,50 m sur l'axe Y
    expect((vAccessors[2]['max']! as List)[1], closeTo(2.5, 1e-6));
    expect(buildGltf(const [])['meshes'], isEmpty);
  });
}
