/// Répartition des morceaux de plinthe dans le moins de barres possible, trait de scie compris.
library;

/// Plus petite chute que l'on garde pour un autre usage.
const reusableOffcutMm = 300;

/// Une barre et les morceaux qu'on y taille.
class CutBar {
  CutBar(this.barMm);

  final int barMm;

  /// Index des morceaux taillés dans cette barre.
  final pieceIndexes = <int>[];
  final pieceLengths = <int>[];

  /// Longueur prise par les morceaux et les traits de scie entre eux.
  int usedMm(int pKerfMm) => pieceLengths.isEmpty
      ? 0
      : pieceLengths.fold<int>(0, (pSum, pLength) => pSum + pLength) +
            pKerfMm * (pieceLengths.length - 1);

  bool fits(int pLengthMm, int pKerfMm) =>
      pieceLengths.isEmpty ? pLengthMm <= barMm : usedMm(pKerfMm) + pKerfMm + pLengthMm <= barMm;

  /// Ce qui reste de la barre après la dernière coupe ; 0 si elle est utilisée jusqu'au bout.
  int offcutMm(int pKerfMm) {
    final vRest = barMm - usedMm(pKerfMm) - pKerfMm;

    return vRest > 0 ? vRest : 0;
  }
}

class BarPlan {
  const BarPlan({required this.bars, required this.kerfMm, required this.tooLong});

  final List<CutBar> bars;
  final int kerfMm;

  /// Index des morceaux plus longs qu'une barre, impossibles à tailler.
  final List<int> tooLong;

  /// Barre dans laquelle tailler le morceau [pIndex], numérotée à partir de 1.
  int? barOf(int pIndex) {
    for (var vBar = 0; vBar < bars.length; vBar++) {
      if (bars[vBar].pieceIndexes.contains(pIndex)) {
        return vBar + 1;
      }
    }

    return null;
  }

  /// Chutes assez longues pour resservir.
  List<int> get reusableOffcuts => [
    for (final vBar in bars)
      if (vBar.offcutMm(kerfMm) >= reusableOffcutMm) vBar.offcutMm(kerfMm),
  ];
}

/// Les morceaux les plus longs d'abord, chacun dans la première barre où il tient.
BarPlan planBars(List<int> pLengths, int pBarMm, int pKerfMm) {
  final vOrder = [for (var vIndex = 0; vIndex < pLengths.length; vIndex++) vIndex]
    ..sort((pA, pB) {
      final vByLength = pLengths[pB].compareTo(pLengths[pA]);

      return vByLength != 0 ? vByLength : pA.compareTo(pB);
    });
  final vBars = <CutBar>[];
  final vTooLong = <int>[];
  for (final vIndex in vOrder) {
    final vLength = pLengths[vIndex];
    if (vLength > pBarMm || vLength <= 0) {
      if (vLength > 0) {
        vTooLong.add(vIndex);
      }
      continue;
    }
    var vBar = vBars.where((pBar) => pBar.fits(vLength, pKerfMm)).firstOrNull;
    if (vBar == null) {
      vBar = CutBar(pBarMm);
      vBars.add(vBar);
    }
    vBar.pieceIndexes.add(vIndex);
    vBar.pieceLengths.add(vLength);
  }
  final rPlan = BarPlan(bars: vBars, kerfMm: pKerfMm, tooLong: vTooLong..sort());

  return rPlan;
}
