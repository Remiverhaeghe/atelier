/// Niveau et inclinomètre du téléphone, à partir de la gravité mesurée par l'accéléromètre.
library;

import 'dart:math' as math;

/// Gravité mesurée sur les trois axes du téléphone (m/s²).
typedef Gravity = ({double x, double y, double z});

/// Écart sous lequel une surface est dite de niveau.
const levelToleranceDeg = 0.3;

/// Inclinaison du téléphone posé à plat sur une surface : 0° à plat, 90° debout.
double tiltDeg(Gravity pGravity) {
  final vSide = math.sqrt(pGravity.x * pGravity.x + pGravity.y * pGravity.y);
  final rTilt = math.atan2(vSide, pGravity.z.abs()) * 180 / math.pi;

  return rTilt;
}

/// Inclinaison sur la longueur et sur la largeur, pour la bulle du niveau.
({double alongDeg, double acrossDeg}) bubble(Gravity pGravity) {
  double vAngle(double pAxis) =>
      math.atan2(pAxis, math.sqrt(pGravity.z * pGravity.z + 1e-12)) * 180 / math.pi;

  return (alongDeg: vAngle(pGravity.y), acrossDeg: vAngle(pGravity.x));
}

/// Pente en pourcentage pour un angle (une pente de douche, une évacuation).
double slopePercent(double pDeg) => math.tan(pDeg * math.pi / 180) * 100;

/// Moyenne des dernières mesures : le téléphone tremble dans la main.
Gravity averageGravity(List<Gravity> pSamples) {
  if (pSamples.isEmpty) {
    return (x: 0, y: 0, z: 9.81);
  }
  var vX = 0.0;
  var vY = 0.0;
  var vZ = 0.0;
  for (final vSample in pSamples) {
    vX += vSample.x;
    vY += vSample.y;
    vZ += vSample.z;
  }
  final vCount = pSamples.length;

  return (x: vX / vCount, y: vY / vCount, z: vZ / vCount);
}

/// Largeur au sol d'un rampant à partir de son angle mesuré au téléphone.
int? runFromAngle({required double pAngleDeg, required int pLowMm, required int pHighMm}) {
  final vRise = pHighMm - pLowMm;
  if (vRise <= 0 || pAngleDeg <= 0.5 || pAngleDeg >= 89.5) {
    return null;
  }
  final rRun = (vRise / math.tan(pAngleDeg * math.pi / 180)).round();

  return rRun;
}
