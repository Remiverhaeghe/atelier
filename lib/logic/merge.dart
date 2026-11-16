/// Chantier partagé : fusion de l'export de quelqu'un d'autre dans son propre chantier.
library;

import 'dart:convert';

import 'worksite.dart';

/// Résultat d'une fusion : le chantier fusionné, et les pièces modifiées des deux côtés,
/// gardées en double pour que rien ne se perde.
typedef MergeResult = ({Worksite worksite, int added, int conflicts});

List<T> _union<T>(List<T> pMine, List<T> pTheirs, String Function(T) pKey) {
  final vSeen = {for (final vItem in pMine) pKey(vItem)};

  return [
    ...pMine,
    for (final vItem in pTheirs)
      if (vSeen.add(pKey(vItem))) vItem,
  ];
}

Map<K, V> _keep<K, V>(Map<K, V> pMine, Map<K, V> pTheirs) => {...pTheirs, ...pMine};

/// Fusionne [pTheirs] dans [pMine] : ce qui manque est ajouté, ce qui est pareil est gardé une
/// fois. Une pièce changée des deux côtés est gardée deux fois, la copie suffixée de
/// [pSuffix] (« Salon (Léa) ») pour qu'on choisisse soi-même.
MergeResult mergeWorksite(Worksite pMine, Worksite pTheirs, String pSuffix) {
  final vMine = {for (final vRoom in pMine.rooms) vRoom.id: vRoom};
  var vAdded = 0;
  var vConflicts = 0;
  final vRooms = [...pMine.rooms];
  for (final vRoom in pTheirs.rooms) {
    final vOwn = vMine[vRoom.id];
    if (vOwn == null) {
      vRooms.add(vRoom);
      vAdded++;
    } else if (jsonEncode(vOwn.toJson()) != jsonEncode(vRoom.toJson())) {
      vRooms.add(vRoom.copyWith(id: '${vRoom.id}-$pSuffix', name: '${vRoom.name} ($pSuffix)'));
      vConflicts++;
    }
  }
  final vWorksite = pMine.copyWith(
    rooms: vRooms,
    prices: _keep(pMine.prices, pTheirs.prices),
    stock: _keep(pMine.stock, pTheirs.stock),
    stores: _keep(pMine.stores, pTheirs.stores),
    references: _keep(pMine.references, pTheirs.references),
    storePrices: _keep(pMine.storePrices, pTheirs.storePrices),
    ownedTools: _union(pMine.ownedTools, pTheirs.ownedTools, (pTool) => pTool),
    bought: _union(pMine.bought, pTheirs.bought, (pItem) => pItem),
    lessons: _union(pMine.lessons, pTheirs.lessons, (pLesson) => pLesson),
    expenses: _union(pMine.expenses, pTheirs.expenses, (pExpense) => pExpense.id),
    journal: _union(pMine.journal, pTheirs.journal, (pEntry) => pEntry.id),
    offcuts: _union(pMine.offcuts, pTheirs.offcuts, (pOffcut) => pOffcut.id),
    reminders: _union(pMine.reminders, pTheirs.reminders, (pReminder) => pReminder.id),
    timeEntries: _union(
      pMine.timeEntries,
      pTheirs.timeEntries,
      (pEntry) => jsonEncode(pEntry.toJson()),
    ),
  );

  return (worksite: vWorksite, added: vAdded, conflicts: vConflicts);
}
