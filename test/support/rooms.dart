import 'package:atelier/logic/room.dart';

/// Pièce rectangulaire de 400 × 300 cm, fermée.
Room rectangleRoom({List<Obstacle> pObstacles = const []}) => Room(
  id: 'salon',
  name: 'Salon',
  walls: const [
    Wall(lengthMm: 4000),
    Wall(lengthMm: 3000),
    Wall(lengthMm: 4000),
    Wall(lengthMm: 3000),
  ],
  obstacles: pObstacles,
);

/// Pièce en L : 500 × 400 cm moins un carré de 200 × 200 cm, avec un coin sortant.
Room lShapedRoom() => const Room(
  id: 'sejour',
  name: 'Séjour',
  walls: [
    Wall(lengthMm: 5000),
    Wall(lengthMm: 2000),
    Wall(lengthMm: 2000, angleToNextDeg: 270),
    Wall(lengthMm: 2000),
    Wall(lengthMm: 3000),
    Wall(lengthMm: 4000),
  ],
);
