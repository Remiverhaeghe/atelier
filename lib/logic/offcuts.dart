/// Chutes gardées sur le chantier et morceaux qu'elles peuvent fournir.
library;

import 'cut_list.dart';
import 'worksite.dart';

/// Matière d'une chute : lame de parquet ou plinthe.
enum OffcutMaterial { plank, baseboard }

/// Trait de scie et équerrage du bout abîmé, perdus à chaque coupe.
const offcutMarginMm = 5;

class Offcut {
  const Offcut({required this.id, required this.material, required this.lengthMm});

  final String id;
  final OffcutMaterial material;
  final int lengthMm;

  Map<String, Object?> toJson() => {'id': id, 'material': material.name, 'lengthMm': lengthMm};

  static Offcut fromJson(Map<String, Object?> pJson) => Offcut(
    id: pJson['id']! as String,
    material: OffcutMaterial.values.byName(pJson['material']! as String),
    lengthMm: pJson['lengthMm']! as int,
  );
}

/// Une chute attribuée à un morceau à couper : pièce, mur ou rangée, longueur.
typedef OffcutUse = ({Offcut offcut, String roomName, int place, int lengthMm});

/// Attribue les chutes aux morceaux du chantier : les plus longs morceaux d'abord, chacun prend
/// la plus petite chute qui suffit, pour garder les grandes chutes aux grands morceaux.
List<OffcutUse> offcutUses(Worksite pWorksite) {
  final vFree = [...pWorksite.offcuts]..sort((pA, pB) => pA.lengthMm.compareTo(pB.lengthMm));
  final vNeeds = <({OffcutMaterial material, String room, int place, int lengthMm})>[
    for (final vRoom in pWorksite.rooms) ...[
      for (final vLine in baseboardCutList(vRoom))
        for (var vCount = 0; vCount < vLine.count; vCount++)
          (
            material: OffcutMaterial.baseboard,
            room: vRoom.name,
            place: vLine.places[vCount % vLine.places.length],
            lengthMm: vLine.lengthMm,
          ),
      for (final vLine in plankCutList(vRoom))
        for (var vCount = 0; vCount < vLine.count; vCount++)
          (
            material: OffcutMaterial.plank,
            room: vRoom.name,
            place: vLine.places[vCount % vLine.places.length],
            lengthMm: vLine.lengthMm,
          ),
    ],
  ]..sort((pA, pB) => pB.lengthMm.compareTo(pA.lengthMm));
  final rUses = <OffcutUse>[];
  for (final vNeed in vNeeds) {
    final vIndex = vFree.indexWhere(
      (pOffcut) =>
          pOffcut.material == vNeed.material && pOffcut.lengthMm >= vNeed.lengthMm + offcutMarginMm,
    );
    if (vIndex >= 0) {
      rUses.add((
        offcut: vFree.removeAt(vIndex),
        roomName: vNeed.room,
        place: vNeed.place,
        lengthMm: vNeed.lengthMm,
      ));
    }
  }

  return rUses;
}
