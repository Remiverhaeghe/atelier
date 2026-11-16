import 'package:atelier/logic/offcuts.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  const vPlank = Offcut(id: 'a', material: OffcutMaterial.plank, lengthMm: 2000);
  const vBoard = Offcut(id: 'b', material: OffcutMaterial.baseboard, lengthMm: 3100);
  const vTiny = Offcut(id: 'c', material: OffcutMaterial.baseboard, lengthMm: 100);

  test('chaque chute va au plus long morceau qu\'elle peut fournir, de la bonne matière', () {
    final vUses = offcutUses(
      Worksite(
        id: 'w',
        name: 'Maison démo',
        rooms: [rectangleRoom()],
        offcuts: const [vTiny, vBoard, vPlank],
      ),
    );

    expect(vUses.map((pUse) => pUse.offcut.id).toSet(), {'a', 'b'});
    for (final vUse in vUses) {
      expect(vUse.lengthMm + offcutMarginMm, lessThanOrEqualTo(vUse.offcut.lengthMm));
      expect(vUse.roomName, 'Salon');
      expect(vUse.place, greaterThan(0));
    }
  });

  test('sans chute ni pièce, rien à proposer', () {
    expect(offcutUses(const Worksite(id: 'w', name: 'Vide', offcuts: [vPlank])), isEmpty);
    expect(offcutUses(Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()])), isEmpty);
  });

  test('les chutes se relisent depuis le JSON', () {
    final vBack = Worksite.fromJson(
      const Worksite(id: 'w', name: 'Maison démo', offcuts: [vPlank, vBoard]).toJson(),
    );

    expect(vBack.offcuts.map((pOffcut) => pOffcut.material), [
      OffcutMaterial.plank,
      OffcutMaterial.baseboard,
    ]);
    expect(vBack.offcuts.last.lengthMm, 3100);
    expect(const Worksite(id: 'w', name: 'Vide').toJson().containsKey('offcuts'), isFalse);
  });
}
