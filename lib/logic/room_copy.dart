/// Copie d'une pièce : à l'identique pour deux chambres pareilles, ou en miroir pour la pièce
/// symétrique de l'autre côté du couloir.
library;

import 'house_book.dart';
import 'room.dart';

/// Même pièce sous un nouveau nom, avancement remis à zéro (rangées, coupes, reprises, photos,
/// solives et photos d'avant fermeture, propres à la pièce d'origine).
Room duplicateRoom(Room pRoom, {required String pId, required String pName}) => pRoom.copyWith(
  id: pId,
  name: pName,
  laidRows: const [],
  cutPieces: const [],
  doneSteps: const [],
  touchUps: const [],
  stepPhotos: const {},
  behindWalls: const BehindWalls(),
);

/// Pièce retournée comme dans un miroir : les murs dans l'ordre inverse, chaque angle passé au
/// coin correspondant, les ouvertures comptées depuis l'autre bout du mur.
///
/// Ce qui est placé par coordonnées (éléments, meubles, réseaux, obstacles) n'est pas repris :
/// leur position n'aurait plus de sens.
Room mirrorRoom(Room pRoom, {required String pId, required String pName}) {
  final vWalls = pRoom.walls;
  final vCount = vWalls.length;
  final rWalls = <Wall>[
    for (var vIndex = 0; vIndex < vCount; vIndex++)
      _mirrorWall(
        vWalls[vCount - 1 - vIndex],
        // Le coin après le nouveau mur était le coin avant l'ancien
        vWalls[(2 * vCount - 2 - vIndex) % vCount],
      ),
  ];
  final rRoom = duplicateRoom(pRoom, pId: pId, pName: pName).copyWith(
    walls: rWalls,
    fixtures: const [],
    furniture: const [],
    networks: const [],
    obstacles: const [],
  );

  return rRoom;
}

Wall _mirrorWall(Wall pWall, Wall pCorner) => Wall(
  lengthMm: pWall.lengthMm,
  angleToNextDeg: pCorner.angleToNextDeg,
  freeEndAfter: pCorner.freeEndAfter,
  openings: [
    for (final vOpening in pWall.openings.reversed)
      Opening(
        kind: vOpening.kind,
        offsetMm: pWall.lengthMm - vOpening.offsetMm - vOpening.widthMm,
        widthMm: vOpening.widthMm,
        threshold: vOpening.threshold,
        heightMm: vOpening.heightMm,
        sillMm: vOpening.sillMm,
      ),
  ],
);
