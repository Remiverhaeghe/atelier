/// Stock de l'atelier, commun à tous les chantiers : vis, colles, finitions, quincaillerie.
/// Chaque article peut répondre à un article des courses ; le stock est alors réparti entre
/// les chantiers, dans leur ordre, et déduit de ce qu'il reste à acheter.
library;

import 'extra_items.dart';
import 'loans.dart';
import 'offcuts.dart';
import 'shopping.dart';
import 'worksite.dart';

enum StockCategory { screws, glue, finish, abrasive, hardware, timber, other }

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    this.category = StockCategory.other,
    this.quantity = 0,
    this.minQuantity = 0,
    this.link,
  });

  final String id;
  final String name;
  final StockCategory category;

  /// Quantité restante, dans l'unité où on l'achète (boîte, tube, cartouche).
  final int quantity;

  /// Seuil d'alerte : à ce niveau ou en dessous, il faut racheter.
  final int minQuantity;

  /// Article des courses auquel il répond (nom d'un ShoppingItem) ; sinon, il répond aux
  /// articles ajoutés aux courses qui portent le même nom.
  final String? link;

  StockItem copyWith({
    String? name,
    StockCategory? category,
    int? quantity,
    int? minQuantity,
    String? link,
    bool clearLink = false,
  }) => StockItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    minQuantity: minQuantity ?? this.minQuantity,
    link: clearLink ? null : link ?? this.link,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'quantity': quantity,
    'minQuantity': minQuantity,
    if (link != null) 'link': link,
  };

  static StockItem fromJson(Map<String, Object?> pJson) => StockItem(
    id: pJson['id']! as String,
    name: (pJson['name'] as String?) ?? '',
    category:
        StockCategory.values.where((pValue) => pValue.name == pJson['category']).firstOrNull ??
        StockCategory.other,
    quantity: (pJson['quantity'] as int?) ?? 0,
    minQuantity: (pJson['minQuantity'] as int?) ?? 0,
    link: pJson['link'] as String?,
  );
}

/// Lit le stock enregistré ; un fichier abîmé redonne un stock vide.
List<StockItem> stockFromJson(Object? pJson) {
  if (pJson is! Map<String, Object?>) {
    return const [];
  }
  final rItems = [
    for (final vItem in (pJson['items'] as List<Object?>?) ?? const [])
      if (vItem is Map<String, Object?>) StockItem.fromJson(vItem),
  ];

  return rItems;
}

Map<String, Object?> stockToJson(List<StockItem> pItems) => {
  'items': [for (final vItem in pItems) vItem.toJson()],
};

/// Vrai quand l'article est au seuil d'alerte ou en dessous.
bool needsRestock(StockItem pItem) => pItem.quantity <= pItem.minQuantity;

/// Ce qu'un chantier prend dans le stock pour un article, et ce qu'il reste à acheter.
typedef StockAllocation = ({
  String worksiteId,
  String itemId,
  int needed,
  int fromStock,
  int toBuy,
});

/// Normalise un nom pour comparer « Vis 4×40 » et « vis 4×40 ».
String _key(String pName) => pName.trim().toLowerCase();

/// Besoin d'un chantier pour l'article [pItem] : la ligne des courses liée, stock du
/// chantier déjà déduit, ou les articles ajoutés du même nom.
int worksiteNeed(Worksite pWorksite, StockItem pItem) {
  final vLink = pItem.link;
  if (vLink != null) {
    final rNeed = shoppingList(
      pWorksite,
    ).where((pLine) => pLine.item.name == vLink).fold(0, (pSum, pLine) => pSum + pLine.quantity);

    return rNeed;
  }
  final rNeed = pWorksite.extras
      .where((pExtra) => _key(pExtra.name) == _key(pItem.name))
      .fold(0, (pSum, pExtra) => pSum + pExtra.quantity);

  return rNeed;
}

/// Répartit le stock entre les chantiers, dans leur ordre : le premier se sert d'abord.
List<StockAllocation> allocateStock(List<StockItem> pItems, List<Worksite> pWorksites) {
  final rAllocations = <StockAllocation>[];
  for (final vItem in pItems) {
    var vLeft = vItem.quantity < 0 ? 0 : vItem.quantity;
    for (final vWorksite in pWorksites) {
      final vNeed = worksiteNeed(vWorksite, vItem);
      if (vNeed <= 0) {
        continue;
      }
      final vTaken = vNeed < vLeft ? vNeed : vLeft;
      vLeft -= vTaken;
      rAllocations.add((
        worksiteId: vWorksite.id,
        itemId: vItem.id,
        needed: vNeed,
        fromStock: vTaken,
        toBuy: vNeed - vTaken,
      ));
    }
  }

  return rAllocations;
}

/// Quantité de l'article une fois servis tous les chantiers prévus.
int projectedQuantity(StockItem pItem, List<StockAllocation> pAllocations) {
  final vTaken = pAllocations
      .where((pAllocation) => pAllocation.itemId == pItem.id)
      .fold(0, (pSum, pAllocation) => pSum + pAllocation.fromStock);

  return pItem.quantity - vTaken;
}

/// Articles à racheter : sous le seuil maintenant, ou une fois les chantiers servis. La
/// quantité conseillée remet au seuil et couvre ce qui manque aux chantiers.
List<({StockItem item, int toBuy})> restockList(
  List<StockItem> pItems,
  List<StockAllocation> pAllocations,
) {
  final rList = <({StockItem item, int toBuy})>[];
  for (final vItem in pItems) {
    final vProjected = projectedQuantity(vItem, pAllocations);
    final vShort = pAllocations
        .where((pAllocation) => pAllocation.itemId == vItem.id)
        .fold(0, (pSum, pAllocation) => pSum + pAllocation.toBuy);
    if (vProjected <= vItem.minQuantity || vShort > 0) {
      final vToBuy = vItem.minQuantity - vProjected + vShort + (vItem.minQuantity > 0 ? 1 : 0);
      rList.add((item: vItem, toBuy: vToBuy < 1 ? 1 : vToBuy));
    }
  }

  return rList;
}

/// Réserve pour [pWorksite] ce que le stock lui donne : la quantité passe dans le stock du
/// chantier (lignes liées) ou diminue l'article ajouté (même nom), et sort du stock de
/// l'atelier. Les courses du chantier en tiennent compte aussitôt.
({List<StockItem> items, Worksite worksite}) reserveFor(
  List<StockItem> pItems,
  Worksite pWorksite,
  List<StockAllocation> pAllocations,
) {
  var vWorksite = pWorksite;
  final vItems = <StockItem>[];
  for (final vItem in pItems) {
    final vTaken = pAllocations
        .where(
          (pAllocation) => pAllocation.worksiteId == pWorksite.id && pAllocation.itemId == vItem.id,
        )
        .fold(0, (pSum, pAllocation) => pSum + pAllocation.fromStock);
    if (vTaken <= 0) {
      vItems.add(vItem);
      continue;
    }
    final vLink = vItem.link;
    if (vLink != null) {
      vWorksite = vWorksite.copyWith(
        stock: {...vWorksite.stock, vLink: (vWorksite.stock[vLink] ?? 0) + vTaken},
      );
    } else {
      var vLeft = vTaken;
      final vExtras = <ExtraItem>[];
      for (final vExtra in vWorksite.extras) {
        if (vLeft > 0 && _key(vExtra.name) == _key(vItem.name)) {
          final vUsed = vExtra.quantity < vLeft ? vExtra.quantity : vLeft;
          vLeft -= vUsed;
          if (vExtra.quantity - vUsed > 0) {
            vExtras.add(vExtra.copyWith(quantity: vExtra.quantity - vUsed));
          }
        } else {
          vExtras.add(vExtra);
        }
      }
      vWorksite = vWorksite.copyWith(extras: vExtras);
    }
    vItems.add(vItem.copyWith(quantity: vItem.quantity - vTaken));
  }
  final rResult = (items: vItems, worksite: vWorksite);

  return rResult;
}

/// Outils prêtés sur tous les chantiers, du plus ancien prêt au plus récent.
List<({String worksite, Loan loan})> allLoans(List<Worksite> pWorksites) {
  final rLoans = [
    for (final vWorksite in pWorksites)
      for (final vLoan in vWorksite.loans) (worksite: vWorksite.name, loan: vLoan),
  ]..sort((pA, pB) => pA.loan.since.compareTo(pB.loan.since));

  return rLoans;
}

/// Chutes gardées sur tous les chantiers : nombre et longueur totale par matière.
Map<OffcutMaterial, ({int count, int lengthMm})> offcutTotals(List<Worksite> pWorksites) {
  final rTotals = <OffcutMaterial, ({int count, int lengthMm})>{};
  for (final vWorksite in pWorksites) {
    for (final vOffcut in vWorksite.offcuts) {
      final vTotal = rTotals[vOffcut.material] ?? (count: 0, lengthMm: 0);
      rTotals[vOffcut.material] = (
        count: vTotal.count + 1,
        lengthMm: vTotal.lengthMm + vOffcut.lengthMm,
      );
    }
  }

  return rTotals;
}

/// Articles des courses qu'un article du stock peut suivre, dans l'ordre de la liste.
List<String> linkableItems() => [for (final vItem in ShoppingItem.values) vItem.name];
