import 'package:atelier/logic/climate_history.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';

/// Chantier fictif des captures : un salon avec porte et radiateur, une chambre en L.
Worksite demoWorksite() => const Worksite(
  id: 'demo',
  name: 'Maison de démonstration',
  rooms: [
    Room(
      id: 'salon',
      name: 'Salon',
      walls: [
        Wall(lengthMm: 4200),
        Wall(lengthMm: 3600),
        Wall(lengthMm: 4200),
        Wall(
          lengthMm: 3600,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 400, widthMm: 830)],
        ),
      ],
      obstacles: [
        Obstacle(kind: ObstacleKind.radiator, wallIndex: 2, offsetMm: 1200, widthMm: 1000),
      ],
      laidRows: [1, 2, 3],
      paint: PaintSettings(walls: true, ceiling: true, woodwork: true),
      cutPieces: [0, 1],
      doneSteps: ['acclimatise'],
      touchUps: [
        TouchUp(
          id: 't1',
          label: 'Peinture du mur de la fenêtre',
          passes: 3,
          donePasses: 1,
          markerXMm: 2100,
          markerYMm: 3300,
        ),
        TouchUp(
          id: 't2',
          label: 'Reboucher les trous de chevilles',
          passes: 2,
          donePasses: 2,
          markerXMm: 600,
          markerYMm: 1800,
        ),
        TouchUp(
          id: 't3',
          label: 'Changer la prise près de la porte',
          note: 'Prise 16 A avec terre',
          toBuy: 'Prise murale blanche',
          markerXMm: 3900,
          markerYMm: 500,
        ),
      ],
    ),
    Room(
      id: 'chambre',
      name: 'Chambre',
      walls: [
        Wall(lengthMm: 3800),
        Wall(lengthMm: 1600),
        Wall(lengthMm: 1200, angleToNextDeg: 270),
        Wall(lengthMm: 1400),
        Wall(lengthMm: 2600),
        Wall(
          lengthMm: 3000,
          openings: [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 730)],
        ),
      ],
    ),
  ],
  prices: {'parquetPacks': 32.9, 'underlayRolls': 19.9, 'baseboardBars': 6.5, 'cartridges': 7.9},
);

/// Chambre en L du dessin : le grand mur du bas n'est pas mesuré, le dessin le déduit.
Room demoSketchRoom() {
  final vChambre = demoWorksite().rooms[1];
  return vChambre.copyWith(
    walls: [
      for (final (vIndex, vWall) in vChambre.walls.indexed)
        vIndex == 0 ? Wall(lengthMm: vWall.lengthMm, deduced: true) : vWall,
    ],
  );
}

/// Salon avec une mezzanine en L le long du mur du fond (position donnée par son centre) : le
/// coin découpé laisse passer l'escalier.
Room demoMezzanineRoom() => demoWorksite().rooms[0].copyWith(
  fixtures: const [
    Fixture(
      id: 'mezz',
      kind: FixtureKind.mezzanine,
      xMm: 2100,
      yMm: 2700,
      widthMm: 4200,
      depthMm: 1800,
      riseMm: 2400,
      notchWidthMm: 1500,
      notchDepthMm: 900,
      notchCorner: 1,
    ),
  ],
);

/// Trois semaines de relevés fictifs : l'humidité baisse après la pose d'une VMC.
ClimateLog demoClimate() {
  final vStart = DateTime(2026, 10, 1);
  return ClimateLog(
    worksOn: DateTime(2026, 10, 11),
    days: [
      for (var vDay = 0; vDay < 21; vDay++)
        ClimateDay(
          day: vStart.add(Duration(days: vDay)),
          tempC: 18.5 + (vDay % 3) * 0.4,
          humidity: vDay < 10 ? 71.0 - (vDay % 4) : 60.0 - (vDay - 10) * 0.6,
          maxHumidity: vDay < 10 ? 79.0 - (vDay % 3) : 66.0 - (vDay - 10) * 0.5,
          count: 24,
        ),
    ],
  );
}
