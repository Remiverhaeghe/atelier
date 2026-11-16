/// Surface habitable (article R156-1 du Code de la construction) et surface Loi Carrez.
///
/// Les murs sont mesurés de l'intérieur : murs et cloisons sont déjà hors du contour.
/// Restent à retirer les marches et trémies d'escalier, les gaines et les parties à moins
/// de 1,80 m sous plafond.
library;

import 'fixtures.dart';
import 'geometry.dart';
import 'room.dart';
import 'slope.dart';

/// Hauteur sous plafond en dessous de laquelle le sol ne compte pas.
const minLivingHeightMm = 1800;

/// Les deux surfaces d'une pièce ou d'un niveau, en m².
typedef LivingArea = ({double habitable, double carrez});

/// Sol où l'on tient debout, moins escaliers, trémies et gaines.
double _countedFloorM2(Room pRoom) {
  if (pRoom.walls.length < 3 || !pRoom.closed) {
    return 0;
  }
  final vStairs = pRoom.fixtures
      .where((pFixture) => pFixture.kind == FixtureKind.stairs)
      .fold(0.0, (pSum, pFixture) => pSum + pFixture.areaM2 * 1e6);
  final vDucts = pRoom.obstacles
      .where((pObstacle) => pObstacle.kind == ObstacleKind.pipe)
      .fold(0, (pSum, pObstacle) => pSum + pObstacle.floorAreaMm2);
  final vArea =
      standingFloorMm2(pRoom, pHeightMm: minLivingHeightMm) -
      vStairs -
      stairwellsMm2(pRoom.fixtures) -
      vDucts;
  final rArea = vArea <= 0 ? 0.0 : vArea / 1e6;

  return rArea;
}

/// Mezzanines dont le plancher est saisi et qui laissent 1,80 m au-dessus, mesuré en leur centre.
double mezzanineLivingM2(Room pRoom) {
  var rArea = 0.0;
  for (final vFixture in pRoom.fixtures) {
    final vFloor = vFixture.riseMm;
    if (vFixture.kind != FixtureKind.mezzanine || vFloor == null) {
      continue;
    }
    final vAbove =
        ceilingHeightAt(pRoom, PlanPoint(vFixture.xMm.toDouble(), vFixture.yMm.toDouble())) -
        vFloor;
    if (vAbove >= minLivingHeightMm) {
      rArea += vFixture.areaM2;
    }
  }

  return rArea;
}

/// Surfaces d'une pièce selon son usage. Une pièce trop basse partout ne compte pas.
LivingArea roomLivingArea(Room pRoom) {
  final vFloor = pRoom.ceilingHeightMm < minLivingHeightMm
      ? 0.0
      : _countedFloorM2(pRoom) + mezzanineLivingM2(pRoom);
  final rArea = (
    habitable: pRoom.usage == RoomUsage.habitable ? vFloor : 0.0,
    // Loi Carrez : combles et véranda fermée comptent, pas les caves, garages et extérieurs
    carrez: switch (pRoom.usage) {
      RoomUsage.habitable || RoomUsage.attic || RoomUsage.veranda => vFloor,
      RoomUsage.cellar || RoomUsage.garage || RoomUsage.outdoor => 0.0,
    },
  );

  return rArea;
}

/// Total de pièces, par exemple d'un niveau ou de la maison.
LivingArea totalLivingArea(Iterable<Room> pRooms) {
  var vHabitable = 0.0;
  var vCarrez = 0.0;
  for (final vRoom in pRooms) {
    final vArea = roomLivingArea(vRoom);
    vHabitable += vArea.habitable;
    vCarrez += vArea.carrez;
  }
  final rTotal = (habitable: vHabitable, carrez: vCarrez);

  return rTotal;
}

/// Sol sous 1,80 m, retiré des deux surfaces : utile pour comprendre l'écart avec le plan.
double lowFloorM2(Room pRoom) {
  if (pRoom.walls.length < 3 || !pRoom.closed) {
    return 0;
  }
  final vAll = outlineAreaMm2(pRoom);
  final vLow = pRoom.ceilingHeightMm < minLivingHeightMm
      ? vAll
      : vAll - standingFloorMm2(pRoom, pHeightMm: minLivingHeightMm);

  return vLow / 1e6;
}
