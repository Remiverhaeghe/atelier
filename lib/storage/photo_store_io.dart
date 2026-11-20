import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Rien à charger : les photos sont lues dans leur fichier quand on en a besoin.
Future<void> loadPhotos() async {}

/// Garde [pBytes] sous le nom [pName] dans le dossier des photos et renvoie son chemin.
Future<String> keepPhoto(String pName, List<int> pBytes) async {
  final vFolder = Directory('${(await getApplicationDocumentsDirectory()).path}/photos');
  await vFolder.create(recursive: true);
  final rPath = '${vFolder.path}/$pName';
  await File(rPath).writeAsBytes(pBytes, flush: true);

  return rPath;
}

/// Contenu de la photo [pPath], ou null si elle a été effacée.
Uint8List? readPhoto(String pPath) {
  final vFile = File(pPath);

  return vFile.existsSync() ? vFile.readAsBytesSync() : null;
}

/// Image à afficher pour la photo [pPath].
ImageProvider photoProvider(String pPath) => FileImage(File(pPath));
