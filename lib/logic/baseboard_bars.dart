/// Plinthes rangées dans des barres, et ordre dans lequel on les coupe.
library;

import 'bar_cutting.dart';
import 'baseboard.dart';
import 'room.dart';

/// Barres à acheter pour [pPieces], onglets et trait de scie compris.
BarPlan planBaseboardBars(List<BaseboardPiece> pPieces, BaseboardSettings pSettings) => planBars(
  [for (final vPiece in pPieces) vPiece.lengthMm],
  pSettings.barLengthMm,
  pSettings.kerfMm,
  pStock: [for (final vPiece in pPieces) vPiece.stockMm(pSettings.thicknessMm)],
);

/// La coupe à faire maintenant et ce qui l'entoure dans sa barre.
class NextBaseboardCut {
  const NextBaseboardCut({
    required this.index,
    required this.piece,
    required this.bar,
    required this.leftInBar,
    required this.offcutMm,
  });

  /// Rang du morceau dans la liste des plinthes.
  final int index;
  final BaseboardPiece piece;

  /// Numéro de la barre (à partir de 1) ; null si le morceau n'entre dans aucune barre.
  final int? bar;

  /// Morceaux de la barre pas encore coupés, celui-ci en premier.
  final List<BaseboardPiece> leftInBar;

  /// Chute de la barre une fois tous ses morceaux coupés.
  final int offcutMm;
}

/// Prochain morceau à couper, barre après barre ; null quand tout est coupé.
NextBaseboardCut? nextBaseboardCut(Room pRoom) {
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  final vBars = planBaseboardBars(vPieces, pRoom.baseboard);
  final vIndex = vBars
      .cutOrder(vPieces.length)
      .where((pIndex) => !pRoom.cutPieces.contains(pIndex))
      .firstOrNull;
  if (vIndex == null) {
    return null;
  }
  final vBar = vBars.barOf(vIndex);
  final vLeft = vBar == null
      ? [vPieces[vIndex]]
      : [
          for (final vOther in vBars.bars[vBar - 1].pieceIndexes)
            if (!pRoom.cutPieces.contains(vOther)) vPieces[vOther],
        ];

  return NextBaseboardCut(
    index: vIndex,
    piece: vPieces[vIndex],
    bar: vBar,
    leftInBar: vLeft,
    offcutMm: vBar == null ? 0 : vBars.bars[vBar - 1].offcutMm(vBars.kerfMm),
  );
}
