import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// Base et table du navigateur où sont rangées les photos.
const photoDatabase = 'atelier';
const photoTable = 'photos';

/// Photos gardées en mémoire après le démarrage : les PDF et l'affichage les lisent sans
/// attendre la base, qui ne répond qu'en différé.
final _photos = <String, Uint8List>{};

/// Charge toutes les photos de la base du navigateur ; à appeler une fois au démarrage.
Future<void> loadPhotos() async {
  try {
    final vDatabase = await _open();
    final vStore = vDatabase.transaction(photoTable.toJS).objectStore(photoTable);
    final vKeys = await _result(vStore.getAllKeys());
    final vValues = await _result(vStore.getAll());
    final vKeyList = (vKeys as JSArray<JSString>).toDart;
    final vValueList = (vValues as JSArray<JSUint8Array>).toDart;
    for (var vIndex = 0; vIndex < vKeyList.length; vIndex++) {
      _photos[vKeyList[vIndex].toDart] = vValueList[vIndex].toDart;
    }
  } on Object {
    // Navigateur sans base (navigation privée) : l'appli marche, sans photos gardées
  }
}

/// Garde [pBytes] sous le nom [pName] dans la base du navigateur et renvoie sa clé.
Future<String> keepPhoto(String pName, List<int> pBytes) async {
  final rKey = 'photos/$pName';
  final vBytes = Uint8List.fromList(pBytes);
  _photos[rKey] = vBytes;
  try {
    final vDatabase = await _open();
    final vStore = vDatabase.transaction(photoTable.toJS, 'readwrite').objectStore(photoTable);
    await _result(vStore.put(vBytes.toJS, rKey.toJS));
  } on Object {
    // Gardée pour la session seulement si la base refuse (stockage plein, navigation privée)
  }

  return rKey;
}

/// Contenu de la photo [pPath], ou null si elle n'est pas dans ce navigateur.
Uint8List? readPhoto(String pPath) => _photos[pPath];

/// Image à afficher pour la photo [pPath] ; une photo absente déclenche l'image d'erreur.
ImageProvider photoProvider(String pPath) => MemoryImage(_photos[pPath] ?? Uint8List(0));

Future<web.IDBDatabase> _open() {
  final vRequest = web.window.indexedDB.open(photoDatabase, 1);
  vRequest.onupgradeneeded = ((web.Event _) {
    (vRequest.result! as web.IDBDatabase).createObjectStore(photoTable);
  }).toJS;

  return _result(vRequest).then((pResult) => pResult! as web.IDBDatabase);
}

/// Réponse d'une requête de la base, sous forme de Future.
Future<JSAny?> _result(web.IDBRequest pRequest) {
  final vDone = Completer<JSAny?>();
  pRequest.onsuccess = ((web.Event _) => vDone.complete(pRequest.result)).toJS;
  pRequest.onerror = ((web.Event _) => vDone.completeError(StateError('base du navigateur'))).toJS;

  return vDone.future;
}
