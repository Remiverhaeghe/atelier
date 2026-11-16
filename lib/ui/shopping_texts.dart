import '../l10n/gen/app_localizations.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';

/// Nom affiché d'un article.
String itemLabel(AppLocalizations pText, ShoppingItem pItem) => switch (pItem) {
  ShoppingItem.parquetPacks => pText.itemParquetPacks,
  ShoppingItem.underlayRolls => pText.itemUnderlayRolls,
  ShoppingItem.glueBuckets => pText.itemGlueBuckets,
  ShoppingItem.nailBoxes => pText.itemNailBoxes,
  ShoppingItem.thresholdBars => pText.itemThresholdBars,
  ShoppingItem.baseboardBars => pText.itemBaseboardBars,
  ShoppingItem.cartridges => pText.itemCartridges,
  ShoppingItem.fixingPoints => pText.itemFixingPoints,
};

/// Prix en euros avec deux décimales : « 30,50 ».
String formatEuros(double pValue) => pValue.toStringAsFixed(2).replaceAll('.', ',');

/// Détail d'une ligne : quantité, prix et total, ou prix à saisir.
String lineDetail(AppLocalizations pText, ShoppingLine pLine) => pLine.unitPrice == null
    ? pText.lineNoPrice(pLine.quantity)
    : pText.lineTotal(pLine.quantity, formatEuros(pLine.unitPrice!), formatEuros(pLine.total!));

/// Liste de courses en texte, à envoyer par message ou à montrer en magasin.
String shoppingText(AppLocalizations pText, Worksite pWorksite) {
  final vLines = shoppingList(pWorksite);
  final rText = StringBuffer(pText.shoppingShareTitle(pWorksite.name))..writeln();
  for (final vLine in vLines) {
    rText.writeln('- ${itemLabel(pText, vLine.item)} : ${lineDetail(pText, vLine)}');
  }
  rText.writeln(pText.budgetTotal(formatEuros(budgetTotal(vLines))));
  if (budgetIncomplete(vLines)) {
    rText.writeln(pText.budgetIncomplete);
  }
  final vPurchases = worksitePurchases(pWorksite);
  if (vPurchases.isNotEmpty) {
    rText.writeln(pText.touchUpsToBuyTitle);
    for (final vPurchase in vPurchases) {
      rText.writeln('- ${vPurchase.item} (${vPurchase.room})');
    }
  }

  return rText.toString().trimRight();
}

/// Valeur du champ de prix : vide tant qu'aucun prix n'est saisi.
String priceField(double? pPrice) => pPrice == null ? '' : formatDecimal(pPrice);
