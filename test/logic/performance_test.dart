import 'package:atelier/logic/furniture.dart';
import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/gltf.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/view3d.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Grande maison fictive : 40 pièces en L, meublées, posées en grille.
Worksite _bigHouse() => Worksite(
  id: 'grande',
  name: 'Grande maison',
  rooms: [
    for (var vIndex = 0; vIndex < 40; vIndex++)
      lShapedRoom().copyWith(
        id: 'p$vIndex',
        name: 'Pièce $vIndex',
        houseXMm: (vIndex % 8) * 6000,
        houseYMm: (vIndex ~/ 8) * 5000,
        level: vIndex ~/ 20,
        furniture: [
          for (var vItem = 0; vItem < 4; vItem++)
            Furniture(
              id: 'm$vItem',
              kind: FurnitureKind.values[vItem],
              xMm: 600 + vItem * 900,
              yMm: 600,
              widthMm: 800,
              depthMm: 500,
            ),
        ],
      ),
  ],
);

void main() {
  // Bornes larges : elles attrapent un calcul devenu quadratique, pas une machine lente
  test('grande maison : vue 3D, glTF et courses restent rapides', () {
    final vHouse = _bigHouse();
    final vWatch = Stopwatch()..start();
    for (var vYaw = 0; vYaw < 360; vYaw += 30) {
      houseFaces(vHouse.rooms, vYaw.toDouble());
    }
    final v3d = vWatch.elapsedMilliseconds;
    buildGltf(vHouse.rooms);
    shoppingList(vHouse);
    vHouse.rooms.fold(0.0, (pSum, pRoom) => pSum + floorAreaM2(pRoom));
    expect(v3d, lessThan(2000), reason: '12 vues 3D en $v3d ms');
    expect(vWatch.elapsedMilliseconds, lessThan(4000));
  });
}
