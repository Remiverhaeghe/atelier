/// Liste de courses et budget d'un chantier : quantités de toutes les pièces et prix saisis.
library;

import 'bar_cutting.dart';
import 'baseboard.dart';
import 'parquet.dart';
import 'room.dart';
import 'touch_up.dart';
import 'worksite.dart';

/// Articles à acheter, dans l'ordre de la liste.
enum ShoppingItem {
  parquetPacks,
  underlayRolls,
  glueBuckets,
  nailBoxes,
  thresholdBars,
  baseboardBars,
  cartridges,
  fixingPoints,
}

class ShoppingLine {
  const ShoppingLine({required this.item, required this.quantity, required this.unitPrice});

  final ShoppingItem item;
  final int quantity;

  /// Prix unitaire saisi, null tant qu'il n'est pas connu.
  final double? unitPrice;

  double? get total => unitPrice == null ? null : unitPrice! * quantity;
}

/// Quantités d'une pièce, arrondies à l'unité vendue.
Map<ShoppingItem, int> roomQuantities(Room pRoom) {
  final rQuantities = <ShoppingItem, int>{};
  if (pRoom.walls.length >= 3) {
    final vParquet = estimateParquet(pRoom, pRoom.parquet);
    rQuantities[ShoppingItem.parquetPacks] = vParquet.packs;
    rQuantities[ShoppingItem.underlayRolls] = vParquet.underlayRolls;
    rQuantities[ShoppingItem.glueBuckets] = vParquet.glueBuckets;
    rQuantities[ShoppingItem.nailBoxes] = vParquet.nailBoxes;
    rQuantities[ShoppingItem.thresholdBars] = thresholdBars(pRoom, pRoom.parquet);
  }
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  final vBars = planBars(
    [for (final vPiece in vPieces) vPiece.lengthMm],
    pRoom.baseboard.barLengthMm,
    pRoom.baseboard.kerfMm,
  );
  final vFixing = fixingNeeds(vPieces, pRoom.baseboard);
  rQuantities[ShoppingItem.baseboardBars] = vBars.bars.length;
  rQuantities[ShoppingItem.cartridges] = vFixing.cartridges;
  rQuantities[ShoppingItem.fixingPoints] = vFixing.points;

  return rQuantities;
}

/// Liste de courses du chantier : chaque pièce est arrondie séparément, les articles à zéro sont omis.
List<ShoppingLine> shoppingList(Worksite pWorksite) {
  final vTotals = <ShoppingItem, int>{};
  for (final vRoom in pWorksite.rooms) {
    roomQuantities(vRoom).forEach((pItem, pQuantity) {
      vTotals[pItem] = (vTotals[pItem] ?? 0) + pQuantity;
    });
  }
  final rLines = [
    for (final vItem in ShoppingItem.values)
      if ((vTotals[vItem] ?? 0) > 0)
        ShoppingLine(
          item: vItem,
          quantity: vTotals[vItem]!,
          unitPrice: pWorksite.prices[vItem.name],
        ),
  ];

  return rLines;
}

/// Total des lignes dont le prix est connu.
double budgetTotal(List<ShoppingLine> pLines) =>
    pLines.fold(0, (pSum, pLine) => pSum + (pLine.total ?? 0));

/// Vrai si un prix manque pour au moins une ligne.
bool budgetIncomplete(List<ShoppingLine> pLines) => pLines.any((pLine) => pLine.unitPrice == null);

/// Coût d'une pièce avec les prix du chantier.
double roomCost(Room pRoom, Map<String, double> pPrices) {
  var rCost = 0.0;
  roomQuantities(pRoom).forEach((pItem, pQuantity) {
    rCost += (pPrices[pItem.name] ?? 0) * pQuantity;
  });

  return rCost;
}

/// Matériel à acheter pour les reprises pas finies, avec la pièce où il servira.
List<({String item, String room})> worksitePurchases(Worksite pWorksite) => [
  for (final vRoom in pWorksite.rooms)
    for (final vItem in touchUpPurchases(vRoom.touchUps)) (item: vItem, room: vRoom.name),
];
