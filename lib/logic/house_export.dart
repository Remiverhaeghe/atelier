/// Export du plan pour d'autres applications (domotique, vue 3D) : format documenté et versionné.
///
/// Le format est décrit dans docs/format-plan.md ; toute évolution incompatible change [planFormatVersion].
library;

import 'geometry.dart';
import 'room.dart';
import 'worksite.dart';

const planFormatName = 'atelier-plan';
const planFormatVersion = 1;

/// Plan du chantier : pièces, contour en millimètres, hauteur, murs et ouvertures.
Map<String, Object?> exportPlan(Worksite pWorksite) => {
  'format': planFormatName,
  'version': planFormatVersion,
  'units': 'mm',
  'name': pWorksite.name,
  'rooms': [
    for (final vRoom in pWorksite.rooms.where((pRoom) => pRoom.walls.length >= 3)) _room(vRoom),
  ],
};

Map<String, Object?> _room(Room pRoom) {
  final vPoints = outline(pRoom);

  return {
    'id': pRoom.id,
    'name': pRoom.name,
    'closed': pRoom.closed,
    'ceilingHeight': pRoom.ceilingHeightMm,
    'floorArea': (floorAreaM2(pRoom) * 1e6).round(),
    // Un sommet par début de mur, dans le sens inverse des aiguilles d'une montre, y vers le haut
    'outline': [
      for (final vPoint in vPoints.take(pRoom.walls.length)) [vPoint.x.round(), vPoint.y.round()],
    ],
    'walls': [
      for (final vWall in pRoom.walls)
        {
          'length': vWall.lengthMm,
          'angleToNext': vWall.angleToNextDeg,
          'openings': [
            for (final vOpening in vWall.openings)
              {
                'kind': vOpening.kind.name,
                'offset': vOpening.offsetMm,
                'width': vOpening.widthMm,
                'height': vOpening.height,
                'sill': vOpening.sill,
              },
          ],
        },
    ],
  };
}
