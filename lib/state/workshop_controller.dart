import 'package:flutter/foundation.dart';

import '../logic/workshop_stock.dart';
import '../storage/workshop_store.dart';

/// Stock de l'atelier partagé par les écrans, enregistré à chaque changement.
class WorkshopController extends ChangeNotifier {
  WorkshopController(this.store);

  final WorkshopStorage store;
  List<StockItem> _items = const [];

  List<StockItem> get items => _items;

  Future<void> load() async {
    _items = await store.load();
    notifyListeners();
  }

  Future<void> replaceAll(List<StockItem> pItems) async {
    _items = pItems;
    notifyListeners();
    await store.save(pItems);
  }

  /// Remplace l'article de même identifiant, ou l'ajoute à la fin.
  Future<void> upsert(StockItem pItem) => replaceAll([
    for (final vItem in _items) vItem.id == pItem.id ? pItem : vItem,
    if (!_items.any((pOther) => pOther.id == pItem.id)) pItem,
  ]);

  Future<void> remove(String pId) => replaceAll([
    for (final vItem in _items)
      if (vItem.id != pId) vItem,
  ]);
}

/// Stock de l'atelier de l'appli : en mémoire jusqu'à ce que main le relie à son fichier.
WorkshopController aWorkshop = WorkshopController(MemoryWorkshopStore());
