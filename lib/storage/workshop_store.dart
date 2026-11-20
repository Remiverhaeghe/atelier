import 'dart:convert';
import 'dart:io';

import '../logic/workshop_stock.dart';

/// Lecture et écriture du stock de l'atelier ; en mémoire dans les tests.
abstract interface class WorkshopStorage {
  Future<List<StockItem>> load();

  Future<void> save(List<StockItem> pItems);
}

/// Stock gardé en mémoire : celui des tests, et celui d'avant le chargement du fichier.
class MemoryWorkshopStore implements WorkshopStorage {
  List<StockItem> saved = const [];

  @override
  Future<List<StockItem>> load() async => saved;

  @override
  Future<void> save(List<StockItem> pItems) async => saved = pItems;
}

/// Stock dans un petit fichier JSON, à côté des chantiers.
class WorkshopFileStore implements WorkshopStorage {
  WorkshopFileStore(this.file);

  final File file;

  @override
  Future<List<StockItem>> load() async {
    if (!file.existsSync()) {
      return const [];
    }
    try {
      return stockFromJson(jsonDecode(await file.readAsString()));
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<StockItem> pItems) async {
    await file.parent.create(recursive: true);
    // Fichier temporaire puis renommage : un arrêt brutal ne laisse pas un fichier coupé
    final vTemporary = File('${file.path}.tmp');
    await vTemporary.writeAsString(jsonEncode(stockToJson(pItems)), flush: true);
    await vTemporary.rename(file.path);
  }
}
