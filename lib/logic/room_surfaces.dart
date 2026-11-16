/// Surfaces d'une pièce reprises par les calculs (isolation, ragréage, faïence) au lieu d'une
/// saisie.
library;

import 'geometry.dart';
import 'insulation.dart';
import 'paint.dart';
import 'room.dart';
import 'slope.dart';

/// Surface des pans inclinés du plafond, en m², plus grande que leur ombre au sol.
double slopedCeilingM2(Room pRoom) {
  if (activeSlopes(pRoom).isEmpty || pRoom.walls.length < 3) {
    return 0;
  }
  final vFlat = outlineAreaMm2(pRoom) - slopedFloorMm2(pRoom);
  final rArea = (ceilingAreaMm2(pRoom) - vFlat) / 1e6;

  return rArea;
}

/// Surface à isoler de [pPart] dans la pièce ; 0 si le plan ne permet pas de la connaître.
double insulationAreaM2(Room pRoom, InsulatedPart pPart) {
  if (pRoom.walls.length < 3) {
    return 0;
  }
  final rArea = switch (pPart) {
    InsulatedPart.lostAttic => outlineAreaMm2(pRoom) / 1e6,
    InsulatedPart.rafters => slopedCeilingM2(pRoom),
    InsulatedPart.walls => paintAreas(pRoom).wallsM2,
    InsulatedPart.floor => floorAreaM2(pRoom),
  };

  return rArea;
}

/// Pan de mur pour la faïence : longueur du mur et hauteur sous plafond à son milieu.
({int widthMm, int heightMm})? wallPanel(Room pRoom, int pWallIndex) {
  if (pWallIndex >= pRoom.walls.length) {
    return null;
  }
  final vPoints = outline(pRoom);
  final vStart = vPoints[pWallIndex];
  final vEnd = vPoints[pWallIndex + 1];
  final vMiddle = PlanPoint((vStart.x + vEnd.x) / 2, (vStart.y + vEnd.y) / 2);
  final rPanel = (
    widthMm: pRoom.walls[pWallIndex].lengthMm,
    heightMm: ceilingHeightAt(pRoom, vMiddle).round(),
  );

  return rPanel;
}
