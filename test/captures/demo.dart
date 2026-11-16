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
