/// Articles ajoutés aux courses depuis un calcul (mezzanine, pergola, tablette murale) :
/// un texte libre et une quantité, à côté des articles calculés à partir des pièces.
library;

import 'touch_up.dart';

class ExtraItem {
  const ExtraItem({required this.name, required this.quantity});

  /// Article tel qu'affiché dans le calcul : « Solives 45 × 145 mm en 450 cm ».
  final String name;
  final int quantity;

  ExtraItem copyWith({int? quantity}) => ExtraItem(name: name, quantity: quantity ?? this.quantity);

  Map<String, Object?> toJson() => {'name': name, 'quantity': quantity};

  static ExtraItem fromJson(Map<String, Object?> pJson) =>
      ExtraItem(name: pJson['name']! as String, quantity: (pJson['quantity'] as int?) ?? 1);
}

/// Ajoute [pAdded] à [pExisting] : un article déjà là voit sa quantité augmenter, les
/// quantités nulles sont ignorées.
List<ExtraItem> mergeExtras(List<ExtraItem> pExisting, List<ExtraItem> pAdded) {
  final rItems = [...pExisting];
  for (final vItem in pAdded.where((pItem) => pItem.quantity > 0)) {
    final vIndex = rItems.indexWhere((pItem) => pItem.name == vItem.name);
    if (vIndex < 0) {
      rItems.add(vItem);
    } else {
      rItems[vIndex] = rItems[vIndex].copyWith(quantity: rItems[vIndex].quantity + vItem.quantity);
    }
  }

  return rItems;
}

/// Quantité en tête d'un article de reprise : « 2 × bande », « 3 x cales », « 2 sacs ».
final _aQuantity = RegExp(r'^(\d+)(?:\s*[×x*]\s*|\s+)(.+)$');

/// Virgule, point-virgule ou « + » entre deux articles ; la virgule d'un nombre (« 2,5 kg ») reste.
final _aSeparator = RegExp(r'(?<!\d),|,(?!\d)|[;+]');

/// Unité juste après le nombre : le nombre est alors une mesure.
final _aUnit = RegExp(r'^(mm|cm|ml|m²|m2|m|kg|g|l)(\s|$)', caseSensitive: false);

/// Ce que les reprises pas finies demandent d'acheter et qui n'est pas encore sur la liste :
/// le champ « à acheter » découpé aux virgules, points-virgules et « + », chaque article une fois.
List<ExtraItem> touchUpShoppingItems(List<TouchUp> pTouchUps, List<ExtraItem> pAlready) {
  final vKnown = {for (final vItem in pAlready) vItem.name.toLowerCase()};
  final rItems = <ExtraItem>[];
  for (final vTouchUp in pTouchUps.where((pTouchUp) => !pTouchUp.done)) {
    for (final vPart in vTouchUp.toBuy.split(_aSeparator)) {
      final vText = vPart.trim();
      if (vText.isEmpty) {
        continue;
      }
      // « 10 mm de joint » est une mesure, pas dix articles
      final vMatch = _aQuantity
          .allMatches(vText)
          .where((pMatch) => !_aUnit.hasMatch(pMatch.group(2)!))
          .firstOrNull;
      final vQuantity = vMatch == null ? 1 : int.parse(vMatch.group(1)!);
      final vName = vMatch == null || vQuantity == 0 ? vText : vMatch.group(2)!.trim();
      if (vKnown.add(vName.toLowerCase())) {
        rItems.add(ExtraItem(name: vName, quantity: vQuantity == 0 ? 1 : vQuantity));
      }
    }
  }

  return rItems;
}
