/// Enduit et ragréage : sacs selon l'épaisseur et la surface, primaire et temps de séchage.
library;

/// Produit à étaler, avec sa consommation en kg par m² et par mm d'épaisseur.
enum Coating {
  /// Ragréage autolissant de sol.
  selfLeveling(1.6, 25),

  /// Enduit de lissage de mur, en poudre.
  skimCoat(1.1, 15),

  /// Enduit de rebouchage pour les trous et fissures.
  filler(1.0, 5);

  const Coating(this.kgPerM2Mm, this.bagKg);

  final double kgPerM2Mm;
  final int bagKg;
}

/// Revêtement posé ensuite sur le ragréage : le parquet attend plus longtemps que le carrelage.
enum Covering { tiles, floating, gluedParquet, vinyl }

/// Primaire d'accrochage sous un ragréage, en litres par m², vendu en bidons de 5 L.
const primerLPerM2 = 0.15;
const primerCanL = 5;

typedef ScreedPlan = ({double kg, int bags, int primerCans, int passes, int dryingHours});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

/// Quantités pour [pAreaM2] à [pThicknessMm] d'épaisseur moyenne, 5 % de perte compris.
ScreedPlan planCoating({
  required Coating pCoating,
  required double pAreaM2,
  required double pThicknessMm,
  Covering pCovering = Covering.floating,
}) {
  final vKg = pAreaM2 * pThicknessMm * pCoating.kgPerM2Mm * 1.05;
  final vLevel = pCoating == Coating.selfLeveling;
  // Un enduit de mur se passe en couches de 2 mm au plus, 24 h entre deux
  final vPasses = vLevel ? 1 : _ceil(pThicknessMm / 2).clamp(1, 20);
  final rPlan = (
    kg: vKg,
    bags: _ceil(vKg / pCoating.bagKg),
    primerCans: vLevel ? _ceil(pAreaM2 * primerLPerM2 / primerCanL) : 0,
    passes: vPasses,
    dryingHours: vLevel ? screedDryingHours(pThicknessMm, pCovering) : 24 * vPasses,
  );

  return rPlan;
}

/// Attente avant de poser sur un ragréage : un jour pour le carrelage, et pour les sols
/// sensibles à l'humidité un jour par tranche de 3 mm (fiches courantes, à vérifier).
int screedDryingHours(double pThicknessMm, Covering pCovering) {
  final vSlices = _ceil(pThicknessMm / 3).clamp(1, 100);
  final rHours = switch (pCovering) {
    Covering.tiles => 24,
    Covering.floating || Covering.vinyl => 24 * vSlices,
    Covering.gluedParquet => 48 * vSlices,
  };

  return rHours;
}

/// Épaisseur moyenne à partir du point le plus bas et du plus haut relevés à la règle.
double averageThickness(double pMinMm, double pMaxMm) => (pMinMm + pMaxMm) / 2;
