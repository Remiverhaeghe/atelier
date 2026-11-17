/// Débit des bois d'une mezzanine : quelles longueurs acheter, et où couper.
library;

import 'bar_cutting.dart';
import 'mezzanine.dart';

/// Longueurs de bois de charpente vendues couramment.
const timberStockMm = [3000, 4000, 4500, 5000, 6000];

/// Trait de scie d'une scie circulaire.
const timberKerfMm = 4;

/// Bois d'une même section à acheter dans une seule longueur.
typedef TimberOrder = ({
  Section section,
  int stockMm,
  int bars,

  /// Longueurs à couper, des plus longues aux plus courtes.
  List<int> pieces,

  /// Morceaux plus longs que la plus grande longueur vendue : à commander sur mesure.
  int tooLong,
  BarPlan plan,
});

/// Longueur du commerce qui demande le moins de bois pour [pPieces], puis le moins de barres.
TimberOrder orderTimber(Section pSection, List<int> pPieces) {
  final vLongest = pPieces.fold(0, (pMax, pPiece) => pPiece > pMax ? pPiece : pMax);
  final vFitting = timberStockMm.where((pStock) => pStock >= vLongest).toList();
  final vCandidates = vFitting.isEmpty ? [timberStockMm.last] : vFitting;
  TimberOrder? rOrder;
  for (final vStock in vCandidates) {
    final vPlan = planBars(pPieces, vStock, timberKerfMm);
    final vBars = vPlan.bars.length;
    final vBetter =
        rOrder == null ||
        vBars * vStock < rOrder.bars * rOrder.stockMm ||
        (vBars * vStock == rOrder.bars * rOrder.stockMm && vBars < rOrder.bars);
    if (vBetter) {
      rOrder = (
        section: pSection,
        stockMm: vStock,
        bars: vBars,
        pieces: [...pPieces]..sort((pA, pB) => pB.compareTo(pA)),
        tooLong: vPlan.tooLong.length,
        plan: vPlan,
      );
    }
  }

  return rOrder!;
}

/// Bois de la mezzanine à acheter : solives et lambourdes ensemble (même section), poteaux.
/// La poutre en lamellé-collé se commande à la longueur, elle n'est pas débitée.
List<TimberOrder> mezzanineTimber(Mezzanine pMezzanine, MezzaninePlan pPlan) {
  final vJoist = pPlan.joist;
  final vPostSide = pPlan.postSideMm;
  final rOrders = <TimberOrder>[
    if (vJoist != null)
      orderTimber(vJoist, [
        for (var vIndex = 0; vIndex < pPlan.joists; vIndex++) pMezzanine.depthMm,
        for (var vIndex = 0; vIndex < pPlan.ledgers; vIndex++) pMezzanine.lengthMm,
      ]),
    if (vPostSide != null && pPlan.postsPerBeam > 0)
      orderTimber((widthMm: vPostSide, heightMm: vPostSide), [
        for (var vIndex = 0; vIndex < pPlan.postsPerBeam * pPlan.beams; vIndex++)
          pMezzanine.postHeightMm,
      ]),
  ];

  return rOrders;
}
