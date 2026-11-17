import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/furniture.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/view3d.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('un sol puis quatre murs, du fond vers l\'avant, et les ouvertures', () {
    final vRoom = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        Wall(lengthMm: 3000),
        Wall(lengthMm: 4000),
        Wall(
          lengthMm: 3000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 830)],
        ),
      ],
    );
    final vFaces = houseFaces([vRoom], 0);

    expect(vFaces.first.kind, FaceKind.floor);
    expect(vFaces.where((pFace) => pFace.kind == FaceKind.wall), hasLength(4));
    expect(vFaces.where((pFace) => pFace.kind == FaceKind.window), hasLength(1));
    // Sans rotation, le mur du fond (y = 3000) est dessiné le premier
    expect(vFaces[1].corners.first.y, 3000);
    final vWindow = vFaces.firstWhere((pFace) => pFace.kind == FaceKind.window);
    expect(vWindow.corners.map((pCorner) => pCorner.z).toSet(), {900.0, 2150.0});
    expect(houseFaces(const [], 0), isEmpty);
  });

  test('un meuble devient un pavé à sa hauteur courante', () {
    final vRoom = rectangleRoom().copyWith(
      furniture: const [
        Furniture(
          id: 'm1',
          kind: FurnitureKind.wardrobe,
          xMm: 1000,
          yMm: 500,
          widthMm: 1000,
          depthMm: 600,
        ),
      ],
    );
    final vFaces = houseFaces([vRoom], 30).where((pFace) => pFace.kind == FaceKind.furniture);

    // Le dessus et quatre côtés
    expect(vFaces, hasLength(5));
    final vHeights = {for (final vFace in vFaces) ...vFace.corners.map((pCorner) => pCorner.z)};
    expect(vHeights, {0.0, 2000.0});
    expect(
      furnitureHeightMm(FurnitureKind.doubleBed),
      lessThan(furnitureHeightMm(FurnitureKind.sofa)),
    );
  });

  test('projection : le haut d\'un mur monte à l\'écran, la rotation tourne le plan', () {
    final vFloor = project((x: 0, y: 0, z: 0), 0);
    final vTop = project((x: 0, y: 0, z: 2500), 0);
    expect(vTop.y, lessThan(vFloor.y));

    final vTurned = project((x: 1000, y: 0, z: 0), 90);
    expect(vTurned.x, closeTo(0, 1e-9));
  });

  test('une mezzanine du plan : plancher à sa hauteur, chants et quatre poteaux', () {
    final vRoom = rectangleRoom().copyWith(
      fixtures: const [
        Fixture(
          id: 'z1',
          kind: FixtureKind.mezzanine,
          xMm: 2000,
          yMm: 1000,
          widthMm: 3000,
          depthMm: 2000,
          riseMm: 2600,
        ),
      ],
    );
    final vFaces = houseFaces([vRoom], 20).where((pFace) => pFace.kind == FaceKind.structure);

    // Quatre poteaux, quatre chants, un plancher
    expect(vFaces, hasLength(9));
    final vHeights = {for (final vFace in vFaces) ...vFace.corners.map((pCorner) => pCorner.z)};
    expect(vHeights, containsAll([0.0, 2350.0, 2600.0]));
  });

  test('une mezzanine sans hauteur saisie : hauteur par défaut', () {
    final vRoom = rectangleRoom().copyWith(
      fixtures: const [
        Fixture(id: 'z1', kind: FixtureKind.mezzanine, xMm: 2000, yMm: 1000, widthMm: 3000, depthMm: 2000),
      ],
    );
    final vTops = houseFaces([vRoom], 0)
        .where((pFace) => pFace.kind == FaceKind.structure)
        .expand((pFace) => pFace.corners.map((pCorner) => pCorner.z));

    expect(vTops.reduce((pA, pB) => pA > pB ? pA : pB), defaultMezzanineRiseMm.toDouble());
  });
}
