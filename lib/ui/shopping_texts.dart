import '../l10n/gen/app_localizations.dart';
import '../logic/paint.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';

/// Nom affiché d'un produit de peinture.
String paintProductLabel(AppLocalizations pText, PaintProduct pProduct) => switch (pProduct) {
  PaintProduct.walls => pText.paintWalls,
  PaintProduct.ceiling => pText.paintCeiling,
  PaintProduct.woodwork => pText.paintWoodwork,
  PaintProduct.primer => pText.paintPrimer,
};

/// Nom affiché d'un article ; un pot de peinture porte son produit et sa contenance.
String itemLabel(AppLocalizations pText, ShoppingItem pItem) {
  final vPaint = pItem.paint;
  if (vPaint != null) {
    return pText.paintPot(paintProductLabel(pText, vPaint), formatDecimal(pItem.potLitres));
  }

  return switch (pItem) {
    ShoppingItem.parquetPacks => pText.itemParquetPacks,
    ShoppingItem.underlayRolls => pText.itemUnderlayRolls,
    ShoppingItem.glueBuckets => pText.itemGlueBuckets,
    ShoppingItem.nailBoxes => pText.itemNailBoxes,
    ShoppingItem.thresholdBars => pText.itemThresholdBars,
    ShoppingItem.baseboardBars => pText.itemBaseboardBars,
    ShoppingItem.cartridges => pText.itemCartridges,
    ShoppingItem.fixingPoints => pText.itemFixingPoints,
    ShoppingItem.rollers => pText.itemRollers,
    ShoppingItem.dropCloths => pText.itemDropCloths,
    ShoppingItem.maskingTape => pText.itemMaskingTape,
    // Les pots de peinture sont traités au-dessus
    _ => '',
  };
}

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

/// Liste courte pour quelqu'un qui passe au magasin : seulement ce qui reste à acheter, par
/// magasin, avec la quantité et la référence, sans prix.
String shortShoppingText(AppLocalizations pText, Worksite pWorksite) {
  final vLeft = [
    for (final vLine in shoppingList(pWorksite))
      if (!pWorksite.bought.contains(vLine.item.name) && vLine.quantity > 0) vLine,
  ];
  final rText = StringBuffer(pText.shortListTitle(pWorksite.name));
  for (final vGroup in groupByStore(vLeft, pWorksite.stores)) {
    rText
      ..writeln()
      ..writeln(vGroup.store.isEmpty ? pText.noStore : vGroup.store);
    for (final vLine in vGroup.lines) {
      final vReference = pWorksite.references[vLine.item.name] ?? '';
      rText.write('- ${vLine.quantity} × ${itemLabel(pText, vLine.item)}');
      rText.writeln(vReference.isEmpty ? '' : ' ($vReference)');
    }
  }
  if (vLeft.isEmpty) {
    rText
      ..writeln()
      ..writeln(pText.shortListDone);
  }

  return rText.toString().trimRight();
}

/// Valeur du champ de prix : vide tant qu'aucun prix n'est saisi.
String priceField(double? pPrice) => pPrice == null ? '' : formatDecimal(pPrice);
