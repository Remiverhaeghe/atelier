/// Articles ajoutés aux courses depuis un calcul (mezzanine, pergola, tablette murale) :
/// un texte libre et une quantité, à côté des articles calculés à partir des pièces.
library;

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
