/// Liste de coupes à emporter à l'atelier : plinthes et lames recoupées, de la plus longue à la plus courte.
library;

import 'baseboard.dart';
import 'laying_plan.dart';
import 'room.dart';

/// Une longueur à couper, regroupée quand plusieurs morceaux sont identiques.
class CutLine {
  const CutLine({
    required this.lengthMm,
    required this.count,
    required this.places,
    this.startCut,
    this.endCut,
  });

  final int lengthMm;
  final int count;

  /// Murs (plinthes) ou rangées (parquet) où vont les morceaux.
  final List<int> places;

  /// Bouts d'une plinthe ; null pour une lame de parquet (coupe droite).
  final EndCut? startCut;
  final EndCut? endCut;
}

/// Regroupe par clé en gardant les endroits, puis trie du plus long au plus court : on coupe
/// d'abord les grands morceaux, les chutes servent ensuite aux petits.
List<CutLine> _grouped(
  List<({String key, int lengthMm, int place, EndCut? start, EndCut? end})> pCuts,
) {
  final vLines = <String, CutLine>{};
  for (final vCut in pCuts) {
    final vLine = vLines[vCut.key];
    vLines[vCut.key] = CutLine(
      lengthMm: vCut.lengthMm,
      count: (vLine?.count ?? 0) + 1,
      places: {...?vLine?.places, vCut.place}.toList()..sort(),
      startCut: vCut.start,
      endCut: vCut.end,
    );
  }
  final rLines = vLines.values.toList()..sort((pA, pB) => pB.lengthMm.compareTo(pA.lengthMm));

  return rLines;
}

/// Morceaux de plinthe, regroupés par longueur et par coupes.
List<CutLine> baseboardCutList(Room pRoom) => _grouped([
  for (final vPiece in baseboardPieces(pRoom, pRoom.baseboard))
    (
      key:
          '${vPiece.lengthMm}|${vPiece.startCut.kind.name}${vPiece.startCut.sawAngleDeg}|'
          '${vPiece.endCut.kind.name}${vPiece.endCut.sawAngleDeg}',
      lengthMm: vPiece.lengthMm,
      place: vPiece.wallNumber,
      start: vPiece.startCut,
      end: vPiece.endCut,
    ),
]);

/// Lames recoupées du plan de pose (les lames entières ne se coupent pas), par longueur.
List<CutLine> plankCutList(Room pRoom) {
  final vPlan = planLaying(pRoom, pRoom.parquet);
  if (vPlan == null) {
    return const [];
  }
  final vFull = pRoom.parquet.plankLengthMm;

  return _grouped([
    for (final vRow in vPlan.rows)
      for (final vRun in vRow.runs)
        for (final vPiece in vRun.pieces)
          if (vPiece != vFull)
            (key: '$vPiece', lengthMm: vPiece, place: vRow.number, start: null, end: null),
  ]);
}
