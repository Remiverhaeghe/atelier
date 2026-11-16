/// Terrasse bois : lames, lambourdes, plots, vis et feutre géotextile.
library;

/// Une lambourde tous les 20 fois l'épaisseur de la lame : 54 cm pour une lame de 27 mm.
const joistSpacingPerThickness = 20;
const deckMarginPercent = 5;
const plotSpacingMm = 600;
const screwsPerCrossing = 2;

class DeckDesign {
  const DeckDesign({
    this.lengthMm = 4000,
    this.widthMm = 3000,
    this.boardWidthMm = 145,
    this.boardThicknessMm = 27,
    this.boardLengthMm = 2400,
    this.gapMm = 5,
    this.joistLengthMm = 4000,
  });

  /// Longueur de la terrasse, dans le sens des lames.
  final int lengthMm;
  final int widthMm;
  final int boardWidthMm;
  final int boardThicknessMm;
  final int boardLengthMm;

  /// Espace entre deux lames, pour que l'eau s'écoule et que le bois travaille.
  final int gapMm;
  final int joistLengthMm;

  DeckDesign copyWith({
    int? lengthMm,
    int? widthMm,
    int? boardWidthMm,
    int? boardThicknessMm,
    int? boardLengthMm,
    int? gapMm,
    int? joistLengthMm,
  }) => DeckDesign(
    lengthMm: lengthMm ?? this.lengthMm,
    widthMm: widthMm ?? this.widthMm,
    boardWidthMm: boardWidthMm ?? this.boardWidthMm,
    boardThicknessMm: boardThicknessMm ?? this.boardThicknessMm,
    boardLengthMm: boardLengthMm ?? this.boardLengthMm,
    gapMm: gapMm ?? this.gapMm,
    joistLengthMm: joistLengthMm ?? this.joistLengthMm,
  );
}

typedef DeckNeeds = ({
  double areaM2,
  int rows,
  int boards,
  int joists,
  int joistSpacingMm,
  int joistBars,
  int plots,
  int screws,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

DeckNeeds deckNeeds(DeckDesign pDesign) {
  if (pDesign.lengthMm <= 0 || pDesign.widthMm <= 0 || pDesign.boardWidthMm <= 0) {
    return (
      areaM2: 0,
      rows: 0,
      boards: 0,
      joists: 0,
      joistSpacingMm: 0,
      joistBars: 0,
      plots: 0,
      screws: 0,
    );
  }
  final vRows = _ceil(pDesign.widthMm / (pDesign.boardWidthMm + pDesign.gapMm));
  final vLinear = vRows * pDesign.lengthMm * (1 + deckMarginPercent / 100);
  final vSpacing = pDesign.boardThicknessMm * joistSpacingPerThickness;
  // Lambourdes en travers des lames, une à chaque bout
  final vJoists = _ceil(pDesign.lengthMm / vSpacing) + 1;
  final vPlotsPerJoist = _ceil(pDesign.widthMm / plotSpacingMm) + 1;
  final rNeeds = (
    areaM2: pDesign.lengthMm * pDesign.widthMm / 1e6,
    rows: vRows,
    boards: pDesign.boardLengthMm <= 0 ? 0 : _ceil(vLinear / pDesign.boardLengthMm),
    joists: vJoists,
    joistSpacingMm: vSpacing,
    joistBars: pDesign.joistLengthMm <= 0
        ? 0
        : _ceil(vJoists * pDesign.widthMm / pDesign.joistLengthMm),
    plots: vJoists * vPlotsPerJoist,
    screws: vRows * vJoists * screwsPerCrossing,
  );

  return rNeeds;
}
