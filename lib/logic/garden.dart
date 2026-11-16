/// Jardin : pelouse semée ou en rouleaux, massifs, terre, paillage et plants.
library;

/// Valeurs courantes, à ajuster d'après le sac ou la notice.
const seedGramsPerM2 = 35;
const seedBoxGrams = 1000;
const turfRollM2 = 1.0;
const turfMarginPercent = 5;
const soilBagLitres = 40;
const mulchBagLitres = 50;

class GardenDesign {
  const GardenDesign({
    this.lawnM2 = 0,
    this.turf = false,
    this.bedsM2 = 0,
    this.soilDepthMm = 200,
    this.mulchDepthMm = 70,
    this.plantsPerM2 = 5,
  });

  final double lawnM2;

  /// Gazon en rouleaux plutôt que semé.
  final bool turf;
  final double bedsM2;

  /// Épaisseur de terre végétale apportée sur les massifs.
  final int soilDepthMm;

  /// Épaisseur de paillage : 5 à 10 cm limitent les herbes indésirables.
  final int mulchDepthMm;
  final int plantsPerM2;

  GardenDesign copyWith({
    double? lawnM2,
    bool? turf,
    double? bedsM2,
    int? soilDepthMm,
    int? mulchDepthMm,
    int? plantsPerM2,
  }) => GardenDesign(
    lawnM2: lawnM2 ?? this.lawnM2,
    turf: turf ?? this.turf,
    bedsM2: bedsM2 ?? this.bedsM2,
    soilDepthMm: soilDepthMm ?? this.soilDepthMm,
    mulchDepthMm: mulchDepthMm ?? this.mulchDepthMm,
    plantsPerM2: plantsPerM2 ?? this.plantsPerM2,
  );
}

/// Quantités à acheter, arrondies à l'unité vendue.
typedef GardenNeeds = ({int seedBoxes, int turfRolls, int soilBags, int mulchBags, int plants});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

GardenNeeds gardenNeeds(GardenDesign pDesign) {
  final vLawn = pDesign.lawnM2 < 0 ? 0.0 : pDesign.lawnM2;
  final vBeds = pDesign.bedsM2 < 0 ? 0.0 : pDesign.bedsM2;
  // Un litre par mètre carré et par millimètre d'épaisseur
  final vSoilLitres = vBeds * pDesign.soilDepthMm;
  final vMulchLitres = vBeds * pDesign.mulchDepthMm;
  final rNeeds = (
    seedBoxes: pDesign.turf ? 0 : _ceil(vLawn * seedGramsPerM2 / seedBoxGrams),
    turfRolls: pDesign.turf ? _ceil(vLawn * (1 + turfMarginPercent / 100) / turfRollM2) : 0,
    soilBags: _ceil(vSoilLitres / soilBagLitres),
    mulchBags: _ceil(vMulchLitres / mulchBagLitres),
    plants: _ceil(vBeds * pDesign.plantsPerM2),
  );

  return rNeeds;
}
