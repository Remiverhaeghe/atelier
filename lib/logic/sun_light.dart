/// Soleil par une fenêtre de toit : position du soleil (formules approchées de la NOAA, à
/// quelques dixièmes de degré près) et tache de lumière sur le sol et le mur d'en face.
///
/// Pièce sous rampant vue en coupe : x part du mur de genou vers l'intérieur, y suit le
/// faîtage (à droite quand on regarde vers l'intérieur), z monte. Le rampant monte de x = 0,
/// à la hauteur du genou, avec la pente donnée ; le mur d'en face est vertical, en x = profondeur.
library;

import 'dart:math' as math;

/// Nord de la France, vers Lille, par défaut.
const defaultLatitudeDeg = 50.6;
const defaultLongitudeDeg = 3.1;

/// Saisons repérées par leur jour de l'année : solstices et équinoxes.
enum Season {
  winter(355),
  spring(80),
  summer(172),
  autumn(266);

  const Season(this.dayOfYear);

  final int dayOfYear;
}

/// Heure d'été en France, du dernier dimanche de mars au dernier dimanche d'octobre : à
/// quelques jours près, du 87e au 300e jour.
int franceUtcOffset(int pDayOfYear) => pDayOfYear >= 87 && pDayOfYear < 300 ? 2 : 1;

typedef SunPosition = ({double elevationDeg, double azimuthDeg});

double _rad(double pDeg) => pDeg * math.pi / 180;
double _deg(double pRad) => pRad * 180 / math.pi;

/// Hauteur du soleil au-dessus de l'horizon et azimut (0 au nord, 90 à l'est, 180 au sud),
/// pour l'heure légale [pHour] du jour [pDayOfYear].
SunPosition sunPosition({
  required int pDayOfYear,
  required double pHour,
  double pLatitudeDeg = defaultLatitudeDeg,
  double pLongitudeDeg = defaultLongitudeDeg,
  int? pUtcOffset,
}) {
  final vOffset = pUtcOffset ?? franceUtcOffset(pDayOfYear);
  final vGamma = 2 * math.pi / 365 * (pDayOfYear - 1 + (pHour - vOffset - 12) / 24);
  final vEquation =
      229.18 *
      (0.000075 +
          0.001868 * math.cos(vGamma) -
          0.032077 * math.sin(vGamma) -
          0.014615 * math.cos(2 * vGamma) -
          0.040849 * math.sin(2 * vGamma));
  final vDeclination =
      0.006918 -
      0.399912 * math.cos(vGamma) +
      0.070257 * math.sin(vGamma) -
      0.006758 * math.cos(2 * vGamma) +
      0.000907 * math.sin(2 * vGamma) -
      0.002697 * math.cos(3 * vGamma) +
      0.00148 * math.sin(3 * vGamma);
  // Temps solaire vrai, en minutes, puis angle horaire : 0 à midi solaire
  final vSolarMinutes = pHour * 60 + vEquation + 4 * pLongitudeDeg - 60 * vOffset;
  final vHourAngle = _rad(vSolarMinutes / 4 - 180);
  final vLatitude = _rad(pLatitudeDeg);
  final vSinElevation =
      math.sin(vLatitude) * math.sin(vDeclination) +
      math.cos(vLatitude) * math.cos(vDeclination) * math.cos(vHourAngle);
  final vElevation = math.asin(vSinElevation.clamp(-1.0, 1.0));
  final vAzimuth = math.atan2(
    math.sin(vHourAngle),
    math.cos(vHourAngle) * math.sin(vLatitude) - math.tan(vDeclination) * math.cos(vLatitude),
  );
  final rPosition = (elevationDeg: _deg(vElevation), azimuthDeg: (_deg(vAzimuth) + 180) % 360);

  return rPosition;
}

/// Pièce et fenêtre : genou, pente, profondeur jusqu'au mur d'en face, et fenêtre de
/// [windowWidthMm] × [windowHeightMm] (le long du rampant) dont le bas est à
/// [windowFromKneeMm] du haut du genou, en suivant le rampant. [facingDeg] est la direction
/// où regarde le toit, vers l'extérieur (180 : plein sud).
typedef AtticWindow = ({
  int kneeMm,
  double slopeDeg,
  int depthMm,
  int windowWidthMm,
  int windowHeightMm,
  int windowFromKneeMm,
  double facingDeg,
});

const defaultAtticWindow = (
  kneeMm: 800,
  slopeDeg: 45.0,
  depthMm: 4000,
  windowWidthMm: 780,
  windowHeightMm: 980,
  windowFromKneeMm: 600,
  facingDeg: 180.0,
);

/// Point d'un plan : au sol (x, y) ou sur le mur d'en face (y, z).
typedef P2 = ({double a, double b});

typedef SunPatch = ({
  SunPosition sun,

  /// Le soleil passe par la fenêtre.
  bool lit,

  /// Tache au sol (x, y) et sur le mur d'en face (y, z), en mm ; vides si rien n'y tombe.
  List<P2> floor,
  List<P2> wall,
});

/// Coins de la fenêtre, dans l'espace de la pièce.
List<({double x, double y, double z})> windowCorners(AtticWindow pRoom) {
  final vCos = math.cos(_rad(pRoom.slopeDeg));
  final vSin = math.sin(_rad(pRoom.slopeDeg));
  final vHalf = pRoom.windowWidthMm / 2;
  final vLow = pRoom.windowFromKneeMm.toDouble();
  final vHigh = vLow + pRoom.windowHeightMm;
  ({double x, double y, double z}) vAt(double pAlong, double pY) =>
      (x: pAlong * vCos, y: pY, z: pRoom.kneeMm + pAlong * vSin);
  final rCorners = [vAt(vLow, -vHalf), vAt(vLow, vHalf), vAt(vHigh, vHalf), vAt(vHigh, -vHalf)];

  return rCorners;
}

/// Coupe le polygone [pPoints] par le demi-plan où [pInside] est positif (Sutherland-Hodgman).
List<P2> clipPolygon(List<P2> pPoints, double Function(P2 pPoint) pInside) {
  final rPoints = <P2>[];
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    final vInA = pInside(vA);
    final vInB = pInside(vB);
    if (vInA >= 0) {
      rPoints.add(vA);
    }
    if ((vInA >= 0) != (vInB >= 0)) {
      final vT = vInA / (vInA - vInB);
      rPoints.add((a: vA.a + (vB.a - vA.a) * vT, b: vA.b + (vB.b - vA.b) * vT));
    }
  }

  return rPoints;
}

/// Tache de soleil à l'instant donné.
SunPatch sunPatch(AtticWindow pRoom, SunPosition pSun) {
  final vElevation = _rad(pSun.elevationDeg);
  // Azimut du soleil ramené aux axes de la pièce : x regarde à l'opposé du toit
  final vRelative = _rad(pSun.azimuthDeg - pRoom.facingDeg - 180);
  final vSx = math.cos(vElevation) * math.cos(vRelative);
  final vSy = math.cos(vElevation) * math.sin(vRelative);
  final vSz = math.sin(vElevation);
  final vSlope = _rad(pRoom.slopeDeg);
  // Normale du rampant vers l'extérieur : le soleil doit être devant
  final vFacing = -math.sin(vSlope) * vSx + math.cos(vSlope) * vSz;
  if (vSz <= 0 || vFacing <= 0) {
    return (sun: pSun, lit: false, floor: const [], wall: const []);
  }
  final vCorners = windowCorners(pRoom);
  final vDepth = pRoom.depthMm.toDouble();
  final vOnFloor = [
    for (final vCorner in vCorners)
      (a: vCorner.x - vCorner.z / vSz * vSx, b: vCorner.y - vCorner.z / vSz * vSy),
  ];
  var vFloor = clipPolygon(vOnFloor, (pPoint) => vDepth - pPoint.a);
  vFloor = clipPolygon(vFloor, (pPoint) => pPoint.a);
  var vWall = <P2>[];
  // Rayons qui vont vers le mur d'en face : la tache y monte au-dessus du sol
  if (-vSx > 1e-9) {
    final vOnWall = [
      for (final vCorner in vCorners)
        (
          a: vCorner.y + (vDepth - vCorner.x) / vSx * vSy,
          b: vCorner.z + (vDepth - vCorner.x) / vSx * vSz,
        ),
    ];
    vWall = clipPolygon(vOnWall, (pPoint) => pPoint.b);
  }
  final rPatch = (sun: pSun, lit: true, floor: vFloor, wall: vWall);

  return rPatch;
}

/// Surface d'un polygone, en m² pour des points en mm.
double patchAreaM2(List<P2> pPoints) {
  var vSum = 0.0;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    vSum += vA.a * vB.b - vB.a * vA.b;
  }

  return vSum.abs() / 2 / 1e6;
}

/// Le point [pPoint] est dans le polygone [pPoints] (règle du rayon).
bool insidePolygon(List<P2> pPoints, P2 pPoint) {
  var rInside = false;
  for (
    var vIndex = 0, vPrevious = pPoints.length - 1;
    vIndex < pPoints.length;
    vPrevious = vIndex++
  ) {
    final vA = pPoints[vIndex];
    final vB = pPoints[vPrevious];
    if ((vA.b > pPoint.b) != (vB.b > pPoint.b) &&
        pPoint.a < (vB.a - vA.a) * (pPoint.b - vA.b) / (vB.b - vA.b) + vA.a) {
      rInside = !rInside;
    }
  }

  return rInside;
}

/// Heures (pas d'une demi-heure, de 5 h à 22 h) où le soleil tombe sur le point du sol
/// [pSpot] : là où l'on pense mettre un lit ou un bureau.
List<double> sunnyHours(
  AtticWindow pRoom,
  P2 pSpot, {
  required int pDayOfYear,
  double pLatitudeDeg = defaultLatitudeDeg,
}) {
  final rHours = <double>[];
  for (var vHalf = 10; vHalf <= 44; vHalf++) {
    final vHour = vHalf / 2;
    final vSun = sunPosition(pDayOfYear: pDayOfYear, pHour: vHour, pLatitudeDeg: pLatitudeDeg);
    final vPatch = sunPatch(pRoom, vSun);
    if (vPatch.floor.length >= 3 && insidePolygon(vPatch.floor, pSpot)) {
      rHours.add(vHour);
    }
  }

  return rHours;
}

/// Étendue en a du polygone [pPoints] sur la ligne b = [pB] ; null si elle ne le coupe pas.
/// Sert à dessiner la tache en bandes fines.
({double from, double to})? polygonSpanAt(List<P2> pPoints, double pB) {
  double? vFrom;
  double? vTo;
  for (var vIndex = 0; vIndex < pPoints.length; vIndex++) {
    final vA = pPoints[vIndex];
    final vB = pPoints[(vIndex + 1) % pPoints.length];
    if ((vA.b - pB) * (vB.b - pB) > 0 || vA.b == vB.b) {
      continue;
    }
    final vX = vA.a + (vB.a - vA.a) * (pB - vA.b) / (vB.b - vA.b);
    vFrom = vFrom == null ? vX : math.min(vFrom, vX);
    vTo = vTo == null ? vX : math.max(vTo, vX);
  }
  if (vFrom == null || vTo == null || vTo - vFrom <= 0) {
    return null;
  }

  return (from: vFrom, to: vTo);
}

/// Heures à la demi-heure regroupées en plages continues : [11, 11.5, 12, 15] donne
/// 11 h à 12 h 30 et 15 h à 15 h 30 (la fin compte la dernière demi-heure).
List<({double from, double to})> hourRanges(List<double> pHours) {
  final rRanges = <({double from, double to})>[];
  for (final vHour in pHours) {
    if (rRanges.isNotEmpty && (rRanges.last.to - vHour).abs() < 1e-9) {
      rRanges.last = (from: rRanges.last.from, to: vHour + 0.5);
    } else {
      rRanges.add((from: vHour, to: vHour + 0.5));
    }
  }

  return rRanges;
}
