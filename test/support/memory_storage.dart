import 'package:atelier/logic/worksite.dart';
import 'package:atelier/storage/worksite_store.dart';

/// Stockage en mémoire : les tests d'écran n'attendent pas le disque.
class MemoryStorage implements WorksiteStorage {
  List<Worksite> saved = const [];

  @override
  Future<List<Worksite>> load() async => saved;

  @override
  Future<void> save(List<Worksite> pWorksites) async => saved = pWorksites;
}
