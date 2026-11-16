/// Export du plan pour d'autres applications (domotique, vue 3D) : format documenté et versionné.
///
/// Le format est décrit dans docs/format-plan.md ; toute évolution incompatible change [planFormatVersion].
library;

import 'geometry.dart';
import 'house.dart';
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
    for (final vRoom in pWorksite.rooms.where((pRoom) => pRoom.walls.length >= 3))
      _room(vRoom, pWorksite.rooms),
  ],
};

Map<String, Object?> _room(Room pRoom, List<Room> pAll) {
  final vPoints = outline(pRoom);

  return {
    'id': pRoom.id,
    'name': pRoom.name,
    'closed': pRoom.closed,
    'ceilingHeight': pRoom.ceilingHeightMm,
    // Niveau et altitude du sol, ajoutés sans changer de version
    'level': pRoom.level,
    'floorLevel': levelBaseMm(pAll, pRoom.level),
    // Plafond rampant, ajouté sans changer de version
    if (pRoom.slope != null)
      'slope': {
        'wall': pRoom.slope!.wallIndex,
        'low': pRoom.slope!.lowMm,
        'run': pRoom.slope!.runMm,
      },
    // Place dans la maison : quarts de tour puis décalage, ajoutés sans changer de version
    'house': {'x': pRoom.houseXMm, 'y': pRoom.houseYMm, 'quarterTurns': pRoom.houseQuarterTurns},
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
    // Prises, interrupteurs, escaliers… dans le repère de la pièce, ajoutés sans changer de version
    'fixtures': [
      for (final vFixture in pRoom.fixtures)
        {
          'kind': vFixture.kind.name,
          'x': vFixture.xMm,
          'y': vFixture.yMm,
          if (vFixture.areaM2 > 0) 'width': vFixture.widthMm,
          if (vFixture.areaM2 > 0) 'depth': vFixture.depthMm,
          if (vFixture.count != 1) 'count': vFixture.count,
        },
    ],
  };
}
