/// Carrelage et faïence : calepinage (carreaux entiers et coupes), quantités, colle, joints.
library;

/// Une coupe en bord plus étroite que ce tiers de carreau se voit et casse : on recentre.
const minEdgeFraction = 1 / 3;

class TilingDesign {
  const TilingDesign({
    this.lengthMm = 3000,
    this.widthMm = 2000,
    this.tileLengthMm = 600,
    this.tileWidthMm = 300,
    this.tileThicknessMm = 9,
    this.jointMm = 3,
    this.boxM2 = 1.44,
    this.marginPercent = 10,
    this.glueKgPerM2 = 5,
    this.centered = true,
  });

  /// Surface à carreler : sol de la pièce ou pan de mur.
  final int lengthMm;
  final int widthMm;
  final int tileLengthMm;
  final int tileWidthMm;
  final int tileThicknessMm;
  final int jointMm;

  /// Surface d'un carton.
  final double boxM2;
  final int marginPercent;
  final double glueKgPerM2;

  /// Calepinage centré : la même coupe des deux côtés ; sinon on part d'un bord.
  final bool centered;

  TilingDesign copyWith({
    int? lengthMm,
    int? widthMm,
    int? tileLengthMm,
    int? tileWidthMm,
    int? tileThicknessMm,
    int? jointMm,
    double? boxM2,
    int? marginPercent,
    double? glueKgPerM2,
    bool? centered,
  }) => TilingDesign(
    lengthMm: lengthMm ?? this.lengthMm,
    widthMm: widthMm ?? this.widthMm,
    tileLengthMm: tileLengthMm ?? this.tileLengthMm,
    tileWidthMm: tileWidthMm ?? this.tileWidthMm,
    tileThicknessMm: tileThicknessMm ?? this.tileThicknessMm,
    jointMm: jointMm ?? this.jointMm,
    boxM2: boxM2 ?? this.boxM2,
    marginPercent: marginPercent ?? this.marginPercent,
    glueKgPerM2: glueKgPerM2 ?? this.glueKgPerM2,
    centered: centered ?? this.centered,
  );
}

/// Répartition sur une direction : carreaux entiers et largeur des coupes de chaque bord.
typedef AxisLayout = ({int fullTiles, int startCutMm, int endCutMm});

/// Calepinage d'une longueur [pSpanMm] avec des carreaux de [pTileMm] et des joints de [pJointMm].
AxisLayout layoutAxis(int pSpanMm, int pTileMm, int pJointMm, {required bool pCentered}) {
  if (pSpanMm <= 0 || pTileMm <= 0) {
    return (fullTiles: 0, startCutMm: 0, endCutMm: 0);
  }
  final vStep = pTileMm + pJointMm;
  var vFull = (pSpanMm + pJointMm) ~/ vStep;
  var vRest = pSpanMm - vFull * vStep;
  if (vRest <= 0) {
    return (fullTiles: vFull, startCutMm: 0, endCutMm: 0);
  }
  if (!pCentered) {
    return (fullTiles: vFull, startCutMm: 0, endCutMm: vRest);
  }
  // Coupes égales des deux côtés ; trop étroites, on remplace un carreau entier par deux coupes
  if (vRest / 2 < pTileMm * minEdgeFraction && vFull > 0) {
    vFull -= 1;
    vRest += vStep;
  }
  final vStart = (vRest - pJointMm) ~/ 2;
  final rLayout = (fullTiles: vFull, startCutMm: vStart, endCutMm: vRest - pJointMm - vStart);

  return rLayout;
}

typedef TilingNeeds = ({
  AxisLayout alongLength,
  AxisLayout alongWidth,
  double areaM2,
  int tiles,
  int boxes,
  int glueKg,
  double jointKg,
  int spacers,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

TilingNeeds tilingNeeds(TilingDesign pDesign) {
  final vArea = pDesign.lengthMm * pDesign.widthMm / 1e6;
  final vTileArea = pDesign.tileLengthMm * pDesign.tileWidthMm / 1e6;
  final vWithMargin = vArea * (1 + pDesign.marginPercent / 100);
  final vTiles = vTileArea <= 0 ? 0 : _ceil(vWithMargin / vTileArea);
  // Joint : ((A + B) / (A × B)) × largeur × profondeur × 1,6 kg par m², profondeur = épaisseur
  final vA = pDesign.tileLengthMm.toDouble();
  final vB = pDesign.tileWidthMm.toDouble();
  final vJointPerM2 = vA <= 0 || vB <= 0
      ? 0.0
      : (vA + vB) / (vA * vB) * pDesign.jointMm * pDesign.tileThicknessMm * 1.6;
  final rNeeds = (
    alongLength: layoutAxis(
      pDesign.lengthMm,
      pDesign.tileLengthMm,
      pDesign.jointMm,
      pCentered: pDesign.centered,
    ),
    alongWidth: layoutAxis(
      pDesign.widthMm,
      pDesign.tileWidthMm,
      pDesign.jointMm,
      pCentered: pDesign.centered,
    ),
    areaM2: vArea,
    tiles: vTiles,
    boxes: pDesign.boxM2 <= 0 ? 0 : _ceil(vWithMargin / pDesign.boxM2),
    glueKg: _ceil(vArea * pDesign.glueKgPerM2),
    jointKg: (vArea * vJointPerM2 * 10).ceil() / 10,
    // Un croisillon par carreau, chacun partagé entre quatre angles
    spacers: vTiles,
  );

  return rNeeds;
}
