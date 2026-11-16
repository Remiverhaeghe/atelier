import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import '../storage/worksite_store.dart';

/// Envoie le chantier dans un fichier JSON, pour une sauvegarde ou un autre téléphone.
Future<void> exportWorksite(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/atelier_$vName.json');
  await vFile.writeAsString(WorksiteStore.encode([pWorksite]));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Ajoute les chantiers d'un fichier exporté, choisi par l'utilisateur.
Future<void> importWorksites(BuildContext pContext, WorksitesController pController) async {
  final vText = AppLocalizations.of(pContext);
  final vMessenger = ScaffoldMessenger.of(pContext);
  final vResult = await FilePicker.platform.pickFiles(withData: true);
  final vBytes = vResult?.files.single.bytes;
  if (vBytes == null) {
    return;
  }
  try {
    final vCount = await pController.importWorksites(WorksiteStore.decode(utf8.decode(vBytes)));
    vMessenger.showSnackBar(SnackBar(content: Text(vText.importDone(vCount))));
  } on FormatException {
    vMessenger.showSnackBar(SnackBar(content: Text(vText.importFailed)));
  }
}
