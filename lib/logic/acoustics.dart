/// Isolation phonique d'une cloison ou d'un plancher de mezzanine : la masse, le ressort
/// (laine) et la désolidarisation (bandes et suspentes) comptent plus que l'épaisseur.
library;

enum SoundCase { partition, mezzanineFloor }

/// Plaque de plâtre phonique courante : 1,20 × 2,50 m.
const soundBoardM2 = 3.0;

/// Une cartouche de mastic acoustique fait environ 10 m de cordon.
const masticMetresPerCartridge = 10.0;

/// Suspentes antivibratiles : fourrures tous les 60 cm, une suspente tous les 1,20 m.
const hangerAreaM2 = 0.72;

typedef SoundPlan = ({
  int boards,
  double woolM2,
  double resilientBandM,
  int mastic,
  int hangers,
  double underlayM2,
});

/// Matériel pour [pAreaM2] de cloison ou de plancher, dont le tour mesure [pPerimeterMm].
///
/// Cloison : une plaque phonique de chaque côté, laine dans l'ossature, bande résiliente sous
/// les rails. Plancher : sous-couche résiliente sous le parquet, laine entre solives et plafond
/// suspendu sur suspentes antivibratiles en dessous.
SoundPlan soundPlan(SoundCase pCase, double pAreaM2, int pPerimeterMm) {
  final vArea = pAreaM2 < 0 ? 0.0 : pAreaM2;
  final vPerimeterM = pPerimeterMm / 1000;
  // 10 % de chutes sur les plaques ; le mastic fait le tour de chaque face
  final vFaces = pCase == SoundCase.partition ? 2 : 1;
  int vCount(double pValue) => (pValue - 1e-9).ceil().clamp(0, 1 << 30);
  final rPlan = (
    boards: vCount(vArea * vFaces * 1.1 / soundBoardM2),
    woolM2: vArea,
    resilientBandM: vPerimeterM,
    mastic: vCount(vPerimeterM * vFaces / masticMetresPerCartridge),
    hangers: pCase == SoundCase.mezzanineFloor ? vCount(vArea / hangerAreaM2) : 0,
    underlayM2: pCase == SoundCase.mezzanineFloor ? vArea * 1.05 : 0.0,
  );

  return rPlan;
}
