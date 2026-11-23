/// Liste de courses et budget d'un chantier : quantités de toutes les pièces et prix saisis.
library;

import 'bar_cutting.dart';
import 'paint.dart';
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
  paintWalls10(PaintProduct.walls, 10),
  paintWalls5(PaintProduct.walls, 5),
  paintWalls2(PaintProduct.walls, 2.5),
  paintCeiling10(PaintProduct.ceiling, 10),
  paintCeiling5(PaintProduct.ceiling, 5),
  paintCeiling2(PaintProduct.ceiling, 2.5),
  primer10(PaintProduct.primer, 10),
  primer5(PaintProduct.primer, 5),
  primer2(PaintProduct.primer, 2.5),
  woodwork2(PaintProduct.woodwork, 2.5),
  woodwork1(PaintProduct.woodwork, 1),
  woodworkHalf(PaintProduct.woodwork, 0.5),
  rollers,
  dropCloths,
  maskingTape;

  const ShoppingItem([this.paint, this.potLitres = 0]);

  /// Pot de peinture : son produit et sa contenance ; null pour les autres articles.
  final PaintProduct? paint;
  final double potLitres;
}

/// Article du pot de [pLitres] litres de [pProduct].
ShoppingItem potItem(PaintProduct pProduct, double pLitres) => ShoppingItem.values.firstWhere(
  (pItem) => pItem.paint == pProduct && pItem.potLitres == pLitres,
);

class ShoppingLine {
  const ShoppingLine({
    required this.item,
    required this.quantity,
    required this.unitPrice,
    this.inStock = 0,
  });

  final ShoppingItem item;

  /// Quantité à acheter, stock déduit.
  final int quantity;

  /// Quantité prise dans le stock déjà là.
  final int inStock;

  /// Prix unitaire saisi, null tant qu'il n'est pas connu.
  final double? unitPrice;

  double? get total => unitPrice == null ? null : unitPrice! * quantity;
}

/// Quantités d'une pièce, arrondies à l'unité vendue ; [pPrices] choisit les pots les moins chers.
Map<ShoppingItem, int> roomQuantities(Room pRoom, [Map<String, double> pPrices = const {}]) {
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
    pStock: [for (final vPiece in vPieces) vPiece.stockMm(pRoom.baseboard.thicknessMm)],
  );
  final vFixing = fixingNeeds(vPieces, pRoom.baseboard);
  rQuantities[ShoppingItem.baseboardBars] = vBars.bars.length;
  rQuantities[ShoppingItem.cartridges] = vFixing.cartridges;
  rQuantities[ShoppingItem.fixingPoints] = vFixing.points;
  paintLitres(pRoom, pRoom.paint).forEach((pProduct, pLitres) {
    final vSizes = potSizes[pProduct]!;
    final vPrices = {
      for (final vSize in vSizes)
        if (pPrices[potItem(pProduct, vSize).name] != null)
          vSize: pPrices[potItem(pProduct, vSize).name]!,
    };
    cheapestPots(pLitres, vSizes, vPrices).forEach((pSize, pCount) {
      rQuantities[potItem(pProduct, pSize)] = pCount;
    });
  });
  final vSupplies = paintSupplies(pRoom, pRoom.paint);
  rQuantities[ShoppingItem.rollers] = vSupplies.rollers;
  rQuantities[ShoppingItem.dropCloths] = vSupplies.dropCloths;
  rQuantities[ShoppingItem.maskingTape] = vSupplies.tapeRolls;

  return rQuantities;
}

/// Liste de courses du chantier : chaque pièce est arrondie séparément, les articles à zéro sont omis.
List<ShoppingLine> shoppingList(Worksite pWorksite) {
  final vTotals = <ShoppingItem, int>{};
  for (final vRoom in pWorksite.rooms) {
    roomQuantities(vRoom, pWorksite.prices).forEach((pItem, pQuantity) {
      vTotals[pItem] = (vTotals[pItem] ?? 0) + pQuantity;
    });
  }
  final rLines = <ShoppingLine>[];
  for (final vItem in ShoppingItem.values) {
    final vNeeded = vTotals[vItem] ?? 0;
    if (vNeeded <= 0) {
      continue;
    }
    final vStock = (pWorksite.stock[vItem.name] ?? 0).clamp(0, vNeeded);
    rLines.add(
      ShoppingLine(
        item: vItem,
        quantity: vNeeded - vStock,
        unitPrice: pWorksite.prices[vItem.name],
        inStock: vStock,
      ),
    );
  }

  return rLines;
}

/// Ce qui restera du stock une fois le chantier fini : à ranger pour plus tard, ou à rapporter au
/// magasin tant que c'est possible. Articles sans besoin compris.
Map<ShoppingItem, int> leftoverStock(Worksite pWorksite) {
  final vTaken = {for (final vLine in shoppingList(pWorksite)) vLine.item: vLine.inStock};
  final rLeft = <ShoppingItem, int>{};
  for (final vItem in ShoppingItem.values) {
    final vLeft = (pWorksite.stock[vItem.name] ?? 0) - (vTaken[vItem] ?? 0);
    if (vLeft > 0) {
      rLeft[vItem] = vLeft;
    }
  }

  return rLeft;
}

/// Total des lignes dont le prix est connu.
double budgetTotal(List<ShoppingLine> pLines) =>
    pLines.fold(0, (pSum, pLine) => pSum + (pLine.total ?? 0));

/// Vrai si un prix manque pour au moins une ligne.
bool budgetIncomplete(List<ShoppingLine> pLines) =>
    pLines.any((pLine) => pLine.quantity > 0 && pLine.unitPrice == null);

/// Coût d'une pièce avec les prix du chantier.
double roomCost(Room pRoom, Map<String, double> pPrices) {
  var rCost = 0.0;
  roomQuantities(pRoom, pPrices).forEach((pItem, pQuantity) {
    rCost += (pPrices[pItem.name] ?? 0) * pQuantity;
  });

  return rCost;
}

/// Matériel à acheter pour les reprises pas finies, avec la pièce où il servira.
List<({String item, String room})> worksitePurchases(Worksite pWorksite) => [
  for (final vRoom in pWorksite.rooms)
    for (final vItem in touchUpPurchases(vRoom.touchUps)) (item: vItem, room: vRoom.name),
];

/// Lignes regroupées par magasin ou rayon, dans l'ordre des noms ; celles sans magasin à la fin.
List<({String store, List<ShoppingLine> lines})> groupByStore(
  List<ShoppingLine> pLines,
  Map<String, String> pStores,
) {
  final vGroups = <String, List<ShoppingLine>>{};
  for (final vLine in pLines) {
    final vStore = (pStores[vLine.item.name] ?? '').trim();
    vGroups.putIfAbsent(vStore, () => []).add(vLine);
  }
  final vNames = vGroups.keys.where((pName) => pName.isNotEmpty).toList()..sort();
  final rGroups = [
    for (final vName in vNames) (store: vName, lines: vGroups[vName]!),
    if (vGroups.containsKey('')) (store: '', lines: vGroups['']!),
  ];

  return rGroups;
}
