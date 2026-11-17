/// Laine soufflée en combles perdus : épaisseur pour la résistance visée, tassement, sacs.
library;

/// Isolants soufflés courants : conductivité (W/m.K), masse posée (kg/m³), tassement après
/// quelques années et poids d'un sac. Valeurs moyennes ; la fiche du produit prime.
enum BlownMaterial {
  glassWool(lambda: 0.045, densityKg: 12, settling: 0.05, bagKg: 16),
  rockWool(lambda: 0.044, densityKg: 25, settling: 0.05, bagKg: 20),
  cellulose(lambda: 0.040, densityKg: 32, settling: 0.20, bagKg: 12.5);

  const BlownMaterial({
    required this.lambda,
    required this.densityKg,
    required this.settling,
    required this.bagKg,
  });

  final double lambda;
  final double densityKg;
  final double settling;
  final double bagKg;
}

/// Résistance thermique demandée en combles perdus pour les aides à la rénovation.
const atticTargetR = 7.0;

typedef BlownPlan = ({int settledMm, int blownMm, int bags, double kg, int rulers});

/// Pour [pAreaM2] de plancher de combles et une résistance [pTargetR] : épaisseur une fois
/// tassée, épaisseur à souffler, sacs, et piges de repère (une pour 10 m²).
BlownPlan planBlown(double pAreaM2, BlownMaterial pMaterial, {double pTargetR = atticTargetR}) {
  final vSettled = pTargetR * pMaterial.lambda;
  final vBlown = vSettled * (1 + pMaterial.settling);
  final vKg = pAreaM2 * vBlown * pMaterial.densityKg;
  final rPlan = (
    settledMm: (vSettled * 1000 - 1e-6).ceil(),
    blownMm: (vBlown * 1000 - 1e-6).ceil(),
    bags: pAreaM2 <= 0 ? 0 : (vKg / pMaterial.bagKg - 1e-9).ceil(),
    kg: vKg,
    rulers: pAreaM2 <= 0 ? 0 : (pAreaM2 / 10 - 1e-9).ceil(),
  );

  return rPlan;
}
