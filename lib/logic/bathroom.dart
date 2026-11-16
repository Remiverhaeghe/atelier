/// Douche de plain-pied : pente vers l'évacuation, hauteur à réserver et étanchéité sous
/// carrelage (SPEC).
library;

/// Évacuation au centre (quatre pentes) ou caniveau le long d'un mur (une seule pente).
enum DrainKind { centre, channel }

/// Pente conseillée du sol de douche vers l'évacuation, en pour cent.
const showerSlopePercent = 2.0;

/// Pente minimale d'un tuyau d'évacuation : un centimètre par mètre.
const pipeSlopePercent = 1.0;

/// Hauteur de l'étanchéité sur les murs de la douche.
const specWallHeightMm = 2000;

typedef Shower = ({
  int widthMm,
  int depthMm,
  DrainKind drain,
  int siphonMm,
  int pipeMm,
  int walls,
});

typedef ShowerPlan = ({
  int runMm,
  int riseMm,
  int drainLevelMm,
  int edgeLevelMm,
  double specFloorM2,
  double specWallM2,
  double cornerBandM,
});

/// Plus longue distance que l'eau parcourt jusqu'à l'évacuation.
int showerRunMm(Shower pShower) => switch (pShower.drain) {
  DrainKind.centre =>
    (pShower.widthMm > pShower.depthMm ? pShower.widthMm : pShower.depthMm) ~/ 2,
  DrainKind.channel => pShower.depthMm,
};

/// Longueur des murs qui bordent la douche : un mur du fond, puis les côtés.
int showerWallsMm(Shower pShower) => switch (pShower.walls.clamp(0, 3)) {
  0 => 0,
  1 => pShower.widthMm,
  2 => pShower.widthMm + pShower.depthMm,
  _ => pShower.widthMm + 2 * pShower.depthMm,
};

/// Niveaux au-dessus de la dalle : à l'évacuation, la hauteur du siphon plus la pente du tuyau ;
/// au bord, la pente du sol en plus. Étanchéité au sol, sur les murs et bandes d'angle.
ShowerPlan showerPlan(Shower pShower) {
  final vRun = showerRunMm(pShower);
  final vRise = (vRun * showerSlopePercent / 100).ceil();
  final vDrain = pShower.siphonMm + (pShower.pipeMm * pipeSlopePercent / 100).ceil();
  final vWalls = showerWallsMm(pShower);
  final vCorners = pShower.walls.clamp(0, 3) - 1;
  final rPlan = (
    runMm: vRun,
    riseMm: vRise,
    drainLevelMm: vDrain,
    edgeLevelMm: vDrain + vRise,
    specFloorM2: pShower.widthMm * pShower.depthMm / 1e6,
    specWallM2: vWalls * specWallHeightMm / 1e6,
    cornerBandM: (vWalls + (vCorners > 0 ? vCorners : 0) * specWallHeightMm) / 1000,
  );

  return rPlan;
}
