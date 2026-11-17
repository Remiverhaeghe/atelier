import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/data_format.dart';
import '../logic/dxf.dart';
import '../logic/encrypted_backup.dart';
import '../logic/gltf.dart';
import '../logic/home_assistant.dart';
import '../logic/house.dart';
import '../logic/house_export.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import '../storage/worksite_store.dart';
import 'encrypted_transfer.dart';

/// Envoie le chantier dans un fichier JSON, pour une sauvegarde ou un autre téléphone.
Future<void> exportWorksite(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/atelier_$vName.json');
  await vFile.writeAsString(WorksiteStore.encode([pWorksite]));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Tous les chantiers dans un seul fichier daté, à envoyer hors du téléphone (Drive, carte SD).
Future<void> exportAllWorksites(List<Worksite> pWorksites, DateTime pDay) async {
  final vFolder = await getTemporaryDirectory();
  final vDate = pDay.toIso8601String().substring(0, 10);
  final vFile = File('${vFolder.path}/atelier_sauvegarde_$vDate.json');
  await vFile.writeAsString(WorksiteStore.encode(pWorksites));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Envoie le plan du chantier au format documenté (docs/format-plan.md), pour la domotique.
Future<void> exportPlanFile(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/plan_$vName.json');
  await vFile.writeAsString(const JsonEncoder.withIndent('  ').convert(exportPlan(pWorksite)));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Étages et pièces pour Home Assistant, partagés comme fichier JSON (voir docs/home-assistant.md).
Future<void> exportHomeAssistantFile(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/home_assistant_$vName.json');
  await vFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(exportHomeAssistant(pWorksite)),
  );
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Maison en 3D au format glTF, partagée comme fichier .gltf (Blender, visualiseurs web).
Future<void> exportGltfFile(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/maison_$vName.gltf');
  await vFile.writeAsString(jsonEncode(buildGltf(houseRooms(pWorksite))));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Plan de la maison en DXF, pour un logiciel de dessin, envoyé par le partage du téléphone.
Future<void> exportDxfFile(Worksite pWorksite) async {
  final vFolder = await getTemporaryDirectory();
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  final vFile = File('${vFolder.path}/plan_$vName.dxf');
  await vFile.writeAsString(buildDxf(houseRooms(pWorksite)));
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}

/// Ajoute les chantiers d'un fichier exporté, choisi par l'utilisateur.
Future<void> importWorksites(BuildContext pContext, WorksitesController pController) async {
  final vText = AppLocalizations.of(pContext);
  final vMessenger = ScaffoldMessenger.of(pContext);
  final vFile = await FilePicker.pickFile();
  if (vFile == null) {
    return;
  }
  final vBytes = await vFile.readAsBytes();
  try {
    var vContent = utf8.decode(vBytes);
    if (isEncryptedBackup(vContent)) {
      if (!pContext.mounted) {
        return;
      }
      final vPassword = await askBackupPassword(pContext);
      if (vPassword == null) {
        return;
      }
      vContent = await decryptBackup(vContent, vPassword);
    }
    final vWorksites = WorksiteStore.decode(vContent);
    if (pController.sharesWorksite(vWorksites) && pContext.mounted) {
      final vMerge = await askMerge(pContext);
      if (vMerge == null) {
        return;
      }
      if (vMerge) {
        final vResult = await pController.mergeImport(vWorksites, vText.mergeSuffix);
        final vMessage = vText.mergeDone(vResult.merged) + vText.mergeConflicts(vResult.conflicts);
        vMessenger.showSnackBar(SnackBar(content: Text(vMessage)));
        return;
      }
    }
    final vCount = await pController.importWorksites(vWorksites);
    vMessenger.showSnackBar(SnackBar(content: Text(vText.importDone(vCount))));
  } on WrongPasswordException {
    vMessenger.showSnackBar(SnackBar(content: Text(vText.backupPasswordWrong)));
  } on NewerFormatException {
    vMessenger.showSnackBar(SnackBar(content: Text(vText.importNewer)));
  } on FormatException {
    vMessenger.showSnackBar(SnackBar(content: Text(vText.importFailed)));
  }
}

/// Le fichier contient un chantier déjà là : fusionner (true), ajouter une copie (false) ou
/// renoncer (null).
Future<bool?> askMerge(BuildContext pContext) {
  final vText = AppLocalizations.of(pContext);

  return showDialog<bool>(
    context: pContext,
    builder: (pDialog) => AlertDialog(
      title: Text(vText.mergeTitle),
      content: Text(vText.mergeHelp),
      actions: [
        TextButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.cancel)),
        TextButton(onPressed: () => Navigator.pop(pDialog, false), child: Text(vText.mergeCopy)),
        FilledButton(onPressed: () => Navigator.pop(pDialog, true), child: Text(vText.mergeAction)),
      ],
    ),
  );
}
