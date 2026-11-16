/// Charpente et couverture d'un pan : chevrons, contre-liteaux, liteaux, tuiles, faîtage, rives
/// et écran sous toiture.
library;

import 'dart:math' as math;

/// Couverture, avec le nombre au m² et le pureau (partie visible, écart entre liteaux) courants.
enum RoofCovering {
  interlockingTile(13, 340),
  flatTile(60, 165),
  slate(30, 230);

  const RoofCovering(this.perM2, this.gaugeMm);

  final double perM2;
  final int gaugeMm;
}

class RoofPan {
  const RoofPan({
    this.lengthMm = 6000,
    this.rafterMm = 4500,
    this.covering = RoofCovering.interlockingTile,
    this.spacingMm = 600,
    this.overhangMm = 300,
  });

  /// Longueur du pan le long de la gouttière, et longueur du rampant de l'égout au faîtage.
  final int lengthMm;
  final int rafterMm;
  final RoofCovering covering;

  /// Entraxe des chevrons, et débord de toit au-delà du mur.
  final int spacingMm;
  final int overhangMm;

  RoofPan copyWith({
    int? lengthMm,
    int? rafterMm,
    RoofCovering? covering,
    int? spacingMm,
    int? overhangMm,
  }) => RoofPan(
    lengthMm: lengthMm ?? this.lengthMm,
    rafterMm: rafterMm ?? this.rafterMm,
    covering: covering ?? this.covering,
    spacingMm: spacingMm ?? this.spacingMm,
    overhangMm: overhangMm ?? this.overhangMm,
  );
}

/// Liteaux et contre-liteaux vendus en 4 m, écran en rouleaux de 75 m², 5 % de casse.
const battenLengthMm = 4000;
const membraneRollM2 = 75;
const roofWastePercent = 5;

/// Faîtières et tuiles de rive : environ 2,5 et 3 au mètre.
const ridgePerM = 2.5;
const vergePerM = 3.0;

typedef RoofNeeds = ({
  int rafters,
  int rafterLengthMm,
  int battenRows,
  int battens,
  int counterBattens,
  double areaM2,
  int coverings,
  int ridgePieces,
  int vergePieces,
  int membraneRolls,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

RoofNeeds roofNeeds(RoofPan pPan) {
  final vArea = pPan.lengthMm * (pPan.rafterMm + pPan.overhangMm) / 1e6;
  final vRafters = pPan.spacingMm <= 0 ? 0 : pPan.lengthMm ~/ pPan.spacingMm + 1;
  final vRows = _ceil((pPan.rafterMm + pPan.overhangMm) / pPan.covering.gaugeMm) + 1;
  final vBattenMm = vRows * pPan.lengthMm * (1 + roofWastePercent / 100);
  final rNeeds = (
    rafters: vRafters,
    rafterLengthMm: pPan.rafterMm + pPan.overhangMm,
    battenRows: vRows,
    battens: _ceil(vBattenMm / battenLengthMm),
    counterBattens: _ceil(vRafters * pPan.rafterMm / battenLengthMm),
    areaM2: vArea,
    coverings: _ceil(vArea * pPan.covering.perM2 * (1 + roofWastePercent / 100)),
    ridgePieces: _ceil(pPan.lengthMm / 1000 * ridgePerM),
    vergePieces: _ceil(2 * (pPan.rafterMm + pPan.overhangMm) / 1000 * vergePerM),
    membraneRolls: math.max(1, _ceil(vArea * 1.1 / membraneRollM2)),
  );

  return rNeeds;
}
