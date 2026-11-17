/// Rayon du magasin où trouver chaque article, pour parcourir les allées dans l'ordre.
library;

import 'shopping.dart';

/// Rayons d'un magasin de bricolage, dans l'ordre d'un parcours habituel.
enum Aisle { timber, flooring, paint, adhesives, building, hardware, other }

Aisle aisleOf(ShoppingItem pItem) => switch (pItem) {
  ShoppingItem.parquetPacks ||
  ShoppingItem.underlayRolls ||
  ShoppingItem.thresholdBars ||
  ShoppingItem.baseboardBars => Aisle.flooring,
  ShoppingItem.glueBuckets || ShoppingItem.cartridges => Aisle.adhesives,
  ShoppingItem.nailBoxes || ShoppingItem.fixingPoints => Aisle.hardware,
  _ => Aisle.paint,
};

/// Mots qui désignent un rayon dans le nom d'un article ajouté depuis un calcul ; le premier
/// rayon dont un mot apparaît l'emporte.
const _aisleWords = <Aisle, List<String>>{
  Aisle.timber: ['bois', 'panneau', 'poutre', 'chevron', 'solive', 'tasseau', 'tourillon'],
  Aisle.adhesives: ['colle', 'mastic', 'joint'],
  Aisle.building: ['béton', 'ciment', 'mortier', 'sac'],
  Aisle.hardware: [
    'vis',
    'cheville',
    'équerre',
    'sabot',
    'goujon',
    'taquet',
    'coulisse',
    'charnière',
    'pied',
  ],
  Aisle.paint: ['peinture', 'rouleau', 'sous-couche'],
};

Aisle aisleOfText(String pName) {
  final vName = pName.toLowerCase();
  for (final vEntry in _aisleWords.entries) {
    if (vEntry.value.any(vName.contains)) {
      return vEntry.key;
    }
  }

  return Aisle.other;
}

/// Lignes regroupées : d'abord par magasin saisi, puis, sans magasin, par rayon conseillé.
List<({String store, Aisle? aisle, List<ShoppingLine> lines})> groupByAisle(
  List<ShoppingLine> pLines,
  Map<String, String> pStores,
) {
  final rGroups = <({String store, Aisle? aisle, List<ShoppingLine> lines})>[];
  for (final vGroup in groupByStore(pLines, pStores)) {
    if (vGroup.store.isNotEmpty) {
      rGroups.add((store: vGroup.store, aisle: null, lines: vGroup.lines));
      continue;
    }
    for (final vAisle in Aisle.values) {
      final vLines = [
        for (final vLine in vGroup.lines)
          if (aisleOf(vLine.item) == vAisle) vLine,
      ];
      if (vLines.isNotEmpty) {
        rGroups.add((store: '', aisle: vAisle, lines: vLines));
      }
    }
  }

  return rGroups;
}
