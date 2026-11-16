/// Contour, surface et contrôle de fermeture d'une pièce saisie mur par mur.
library;

import 'dart:math' as math;

import 'room.dart';

/// Point du plan, en millimètres.
class PlanPoint {
  const PlanPoint(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(PlanPoint pOther) => math.sqrt(math.pow(x - pOther.x, 2) + math.pow(y - pOther.y, 2));
}

/// Écart toléré entre la fin du dernier mur et le début du premier : 1 cm.
const closureToleranceMm = 10.0;

/// Sommets du contour : le premier mur part de l'origine vers la droite, chaque coin tourne à gauche.
List<PlanPoint> outline(Room pRoom) {
  final rPoints = <PlanPoint>[const PlanPoint(0, 0)];
  var vHeading = 0.0;
  for (final vWall in pRoom.walls) {
    final vLast = rPoints.last;
    rPoints.add(
      PlanPoint(
        vLast.x + vWall.lengthMm * math.cos(vHeading),
        vLast.y + vWall.lengthMm * math.sin(vHeading),
      ),
    );
    // Angle intérieur de 90° : on tourne de 90° ; 270° (coin sortant) : on tourne de -90°.
    vHeading += math.pi - vWall.angleToNextDeg * math.pi / 180;
  }

  return rPoints;
}

/// Distance entre la fin du dernier mur et le point de départ ; 0 pour une pièce ouverte.
double closureGapMm(Room pRoom) {
  if (!pRoom.closed || pRoom.walls.isEmpty) {
    return 0;
  }
  final vPoints = outline(pRoom);
  final rGap = vPoints.last.distanceTo(vPoints.first);

  return rGap;
}

/// Vrai si le contour se referme à 1 cm près : sinon une mesure ou un angle est faux.
bool closesProperly(Room pRoom) => closureGapMm(pRoom) <= closureToleranceMm;

/// Surface du contour en mm² (formule du lacet), sans retirer les obstacles.
double outlineAreaMm2(Room pRoom) {
  if (pRoom.walls.length < 3) {
    return 0;
  }
  final vPoints = outline(pRoom);
  var vTwiceArea = 0.0;
  for (var vIndex = 0; vIndex < vPoints.length - 1; vIndex++) {
    vTwiceArea += vPoints[vIndex].x * vPoints[vIndex + 1].y - vPoints[vIndex + 1].x * vPoints[vIndex].y;
  }
  final rArea = vTwiceArea.abs() / 2;

  return rArea;
}

/// Surface au sol à couvrir de parquet, en m² : contour moins les zones sans parquet.
double floorAreaM2(Room pRoom) {
  final vObstacles = pRoom.obstacles.fold<int>(0, (pSum, pObstacle) => pSum + pObstacle.floorAreaMm2);
  final vArea = outlineAreaMm2(pRoom) - vObstacles;
  final rArea = vArea <= 0 ? 0.0 : vArea / 1e6;

  return rArea;
}

/// Longueur totale des murs, en millimètres.
int perimeterMm(Room pRoom) => pRoom.walls.fold(0, (pSum, pWall) => pSum + pWall.lengthMm);
