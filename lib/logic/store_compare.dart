/// Comparatif de magasins : total de la liste de courses par magasin et meilleur panier mixte.
library;

import 'shopping.dart';

/// Total d'un magasin : lignes dont il donne le prix, et nombre de lignes sans prix chez lui.
typedef StoreTotal = ({String store, double total, int missing});

/// Total de chaque magasin, complets d'abord puis du moins cher au plus cher.
List<StoreTotal> storeTotals(List<ShoppingLine> pLines, Map<String, Map<String, double>> pPrices) {
  final vLines = pLines.where((pLine) => pLine.quantity > 0).toList();
  final rTotals = [
    for (final vEntry in pPrices.entries)
      (
        store: vEntry.key,
        total: vLines.fold(
          0.0,
          (pSum, pLine) => pSum + (vEntry.value[pLine.item.name] ?? 0) * pLine.quantity,
        ),
        missing: vLines.where((pLine) => !vEntry.value.containsKey(pLine.item.name)).length,
      ),
  ]..sort((pA, pB) {
      final vMissing = pA.missing.compareTo(pB.missing);
      return vMissing != 0 ? vMissing : pA.total.compareTo(pB.total);
    });

  return rTotals;
}

/// Panier mixte : chaque article là où il est le moins cher.
typedef BestBasket = ({double total, Map<String, String> storeOf, int missing});

BestBasket bestBasket(List<ShoppingLine> pLines, Map<String, Map<String, double>> pPrices) {
  var vTotal = 0.0;
  var vMissing = 0;
  final vStoreOf = <String, String>{};
  for (final vLine in pLines.where((pLine) => pLine.quantity > 0)) {
    String? vBest;
    double? vBestPrice;
    for (final vEntry in pPrices.entries) {
      final vPrice = vEntry.value[vLine.item.name];
      if (vPrice != null && (vBestPrice == null || vPrice < vBestPrice)) {
        vBest = vEntry.key;
        vBestPrice = vPrice;
      }
    }
    if (vBest == null) {
      vMissing++;
      continue;
    }
    vStoreOf[vLine.item.name] = vBest;
    vTotal += vBestPrice! * vLine.quantity;
  }
  final rBasket = (total: vTotal, storeOf: vStoreOf, missing: vMissing);

  return rBasket;
}
