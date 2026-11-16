/// État des chantiers partagé par les écrans, enregistré à chaque changement.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../logic/merge.dart';
import '../logic/room.dart';
import '../logic/worksite.dart';
import '../storage/worksite_store.dart';

class WorksitesController extends ChangeNotifier {
  WorksitesController(this.store, {String Function()? pNewId})
    : newId = pNewId ?? (() => DateTime.now().microsecondsSinceEpoch.toString());

  final WorksiteStorage store;
  final String Function() newId;

  List<Worksite> _worksites = const [];
  bool _loaded = false;

  List<Worksite> get worksites => _worksites;
  bool get loaded => _loaded;

  Future<void> load() async {
    try {
      _worksites = await store.load();
    } on FormatException catch (vError) {
      // Fichier illisible : on repart de zéro sans l'écraser tant que rien n'est modifié.
      developer.log('Chantiers illisibles : $vError', name: 'atelier.storage');
      _worksites = const [];
    }
    _loaded = true;
    notifyListeners();
  }

  Worksite? worksite(String pId) {
    for (final vWorksite in _worksites) {
      if (vWorksite.id == pId) {
        return vWorksite;
      }
    }

    return null;
  }

  Future<Worksite> addWorksite(String pName) async {
    final rWorksite = Worksite(id: newId(), name: pName.trim());
    await replaceAll([..._worksites, rWorksite]);

    return rWorksite;
  }

  Future<void> updateWorksite(Worksite pWorksite) => replaceAll([
    for (final vWorksite in _worksites) vWorksite.id == pWorksite.id ? pWorksite : vWorksite,
  ]);

  Future<void> deleteWorksite(String pId) => replaceAll([
    for (final vWorksite in _worksites)
      if (vWorksite.id != pId) vWorksite,
  ]);

  Future<Room> addRoom(String pWorksiteId, String pName) async {
    final rRoom = Room(id: newId(), name: pName.trim());
    final vWorksite = worksite(pWorksiteId)!;
    await updateWorksite(vWorksite.copyWith(rooms: [...vWorksite.rooms, rRoom]));

    return rRoom;
  }

  Future<void> updateRoom(String pWorksiteId, Room pRoom) {
    final vWorksite = worksite(pWorksiteId)!;

    return updateWorksite(
      vWorksite.copyWith(
        rooms: [for (final vRoom in vWorksite.rooms) vRoom.id == pRoom.id ? pRoom : vRoom],
      ),
    );
  }

  Future<void> deleteRoom(String pWorksiteId, String pRoomId) {
    final vWorksite = worksite(pWorksiteId)!;

    return updateWorksite(
      vWorksite.copyWith(
        rooms: [
          for (final vRoom in vWorksite.rooms)
            if (vRoom.id != pRoomId) vRoom,
        ],
      ),
    );
  }

  /// Ajoute des chantiers importés sous de nouveaux identifiants : un import ne remplace rien.
  Future<int> importWorksites(List<Worksite> pWorksites) async {
    await replaceAll([
      ..._worksites,
      for (final vWorksite in pWorksites) vWorksite.copyWith(id: newId()),
    ]);

    return pWorksites.length;
  }

  /// Chantier partagé : un chantier déjà là est fusionné avec celui du fichier, les autres sont
  /// ajoutés en gardant leur identifiant pour les fusions suivantes.
  Future<({int added, int merged, int conflicts})> mergeImport(
    List<Worksite> pWorksites,
    String pSuffix,
  ) async {
    final vWorksites = [..._worksites];
    var vAdded = 0;
    var vMerged = 0;
    var vConflicts = 0;
    for (final vTheirs in pWorksites) {
      final vIndex = vWorksites.indexWhere((pWorksite) => pWorksite.id == vTheirs.id);
      if (vIndex < 0) {
        vWorksites.add(vTheirs);
        vAdded++;
      } else {
        final vResult = mergeWorksite(vWorksites[vIndex], vTheirs, pSuffix);
        vWorksites[vIndex] = vResult.worksite;
        vMerged++;
        vConflicts += vResult.conflicts;
      }
    }
    await replaceAll(vWorksites);

    return (added: vAdded, merged: vMerged, conflicts: vConflicts);
  }

  /// Le fichier contient au moins un chantier qu'on a déjà : la fusion a un sens.
  bool sharesWorksite(List<Worksite> pWorksites) => pWorksites.any(
    (pTheirs) => _worksites.any((pWorksite) => pWorksite.id == pTheirs.id),
  );

  Future<void> replaceAll(List<Worksite> pWorksites) async {
    _worksites = List.unmodifiable(pWorksites);
    notifyListeners();
    await store.save(_worksites);
  }
}
