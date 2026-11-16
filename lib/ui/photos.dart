import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Prend une photo pour la reprise [pId] et renvoie son chemin, ou null si annulée.
typedef PhotoTaker = Future<String?> Function(String pId);

/// Photo prise avec l'appareil, réduite et copiée dans le dossier de l'application.
///
/// Passer par l'appareil photo du téléphone évite de demander la permission caméra.
Future<String?> takePhoto(String pId) async {
  final vPicked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1600,
    imageQuality: 75,
  );
  if (vPicked == null) {
    return null;
  }
  final vFolder = Directory('${(await getApplicationDocumentsDirectory()).path}/photos');
  await vFolder.create(recursive: true);
  final rPath = '${vFolder.path}/$pId-${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(vPicked.path).copy(rPath);

  return rPath;
}

/// Photo en grand, à toucher pour fermer.
Future<void> showPhoto(BuildContext pContext, String pPath) => showDialog<void>(
  context: pContext,
  builder: (pDialogContext) => GestureDetector(
    onTap: () => Navigator.pop(pDialogContext),
    child: InteractiveViewer(child: Image.file(File(pPath))),
  ),
);
