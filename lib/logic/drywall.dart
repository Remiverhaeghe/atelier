/// Placo et isolation : plaques, ossature, vis, bandes, enduit et laine.
library;

/// Valeurs courantes, à vérifier sur la notice des produits.
const plateWidthMm = 1200;
const plateHeightMm = 2500;
const profileLengthMm = 3000;
const screwsPerM2 = 20;
const tapeMetresPerM2 = 1.5;
const tapeRollMetres = 150;
const fillerKgPerM2 = 0.4;
const fillerBagKg = 25;
const drywallMarginPercent = 10;

class DrywallDesign {
  const DrywallDesign({
    this.lengthMm = 4000,
    this.heightMm = 2500,
    this.partition = false,
    this.studSpacingMm = 600,
    this.insulationMm = 100,
    this.lambda = 0.035,
    this.insulationRollM2 = 5,
  });

  /// Longueur de mur à doubler ou de cloison à monter.
  final int lengthMm;
  final int heightMm;

  /// Cloison : des plaques sur les deux faces ; sinon doublage d'un mur, une face.
  final bool partition;

  /// Écart entre deux montants, 60 cm d'habitude.
  final int studSpacingMm;

  /// Épaisseur de laine ; 0 sans isolation.
  final int insulationMm;

  /// Conductivité de la laine (W/m·K), écrite sur l'emballage.
  final double lambda;
  final double insulationRollM2;

  DrywallDesign copyWith({
    int? lengthMm,
    int? heightMm,
    bool? partition,
    int? studSpacingMm,
    int? insulationMm,
    double? lambda,
    double? insulationRollM2,
  }) => DrywallDesign(
    lengthMm: lengthMm ?? this.lengthMm,
    heightMm: heightMm ?? this.heightMm,
    partition: partition ?? this.partition,
    studSpacingMm: studSpacingMm ?? this.studSpacingMm,
    insulationMm: insulationMm ?? this.insulationMm,
    lambda: lambda ?? this.lambda,
    insulationRollM2: insulationRollM2 ?? this.insulationRollM2,
  );
}

/// Quantités à acheter et résistance thermique de la laine.
typedef DrywallNeeds = ({
  double areaM2,
  int plates,
  int rails,
  int studs,
  int screws,
  int tapeRolls,
  int fillerBags,
  int insulationRolls,
  double resistance,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

DrywallNeeds drywallNeeds(DrywallDesign pDesign) {
  final vArea = pDesign.lengthMm * pDesign.heightMm / 1e6;
  final vFaces = pDesign.partition ? 2 : 1;
  final vPlated = vArea * vFaces;
  final vMargin = 1 + drywallMarginPercent / 100;
  final vSpacing = pDesign.studSpacingMm <= 0 ? 600 : pDesign.studSpacingMm;
  // Un montant à chaque bout et tous les 60 cm ; plus long que 3 m, on aboute deux profilés
  final vStudCount = pDesign.lengthMm <= 0 ? 0 : _ceil(pDesign.lengthMm / vSpacing) + 1;
  final vStudPieces = _ceil(pDesign.heightMm / profileLengthMm);
  final rNeeds = (
    areaM2: vArea,
    plates: _ceil(vPlated * vMargin / (plateWidthMm * plateHeightMm / 1e6)),
    rails: _ceil(2 * pDesign.lengthMm / profileLengthMm),
    studs: vStudCount * vStudPieces,
    screws: _ceil(vPlated * screwsPerM2),
    tapeRolls: _ceil(vPlated * tapeMetresPerM2 / tapeRollMetres),
    fillerBags: _ceil(vPlated * fillerKgPerM2 / fillerBagKg),
    insulationRolls: pDesign.insulationMm <= 0 || pDesign.insulationRollM2 <= 0
        ? 0
        : _ceil(vArea * vMargin / pDesign.insulationRollM2),
    // R = épaisseur / conductivité, en m²·K/W
    resistance: pDesign.lambda <= 0 ? 0.0 : pDesign.insulationMm / 1000 / pDesign.lambda,
  );

  return rNeeds;
}
