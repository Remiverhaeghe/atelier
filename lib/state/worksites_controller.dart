/// État des chantiers partagé par les écrans, enregistré à chaque changement.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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

  Future<void> replaceAll(List<Worksite> pWorksites) async {
    _worksites = List.unmodifiable(pWorksites);
    notifyListeners();
    await store.save(_worksites);
  }
}
