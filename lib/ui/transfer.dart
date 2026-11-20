import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/data_format.dart';
import '../logic/dxf.dart';
import '../logic/encrypted_backup.dart';
import '../logic/gltf.dart';
import '../logic/home_assistant.dart';
import '../logic/house.dart';
import '../logic/house_export.dart';
import '../logic/project_bundle.dart';
import '../logic/worksite.dart';
import '../state/workshop_controller.dart';
import '../state/worksites_controller.dart';
import '../storage/worksite_store.dart';
import 'encrypted_transfer.dart';
import 'share_file.dart';

/// Envoie le chantier dans un fichier JSON, pour une sauvegarde ou un autre téléphone.
Future<void> exportWorksite(Worksite pWorksite) async {
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile(
    'atelier_$vName.json',
    WorksiteStore.encode([pWorksite]),
    pMime: 'application/json',
  );
}

/// Tous les chantiers dans un seul fichier daté, à envoyer hors du téléphone (Drive, carte SD).
Future<void> exportAllWorksites(List<Worksite> pWorksites, DateTime pDay) async {
  final vDate = pDay.toIso8601String().substring(0, 10);
  await shareTextFile(
    'atelier_sauvegarde_$vDate.json',
    // Sauvegarde complète : le stock de l'atelier part avec les chantiers
    WorksiteStore.encode(pWorksites, pWorkshop: aWorkshop.items),
  );
}

/// Envoie le plan du chantier au format documenté (docs/format-plan.md), pour la domotique.
Future<void> exportPlanFile(Worksite pWorksite) async {
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile(
    'plan_$vName.json',
    const JsonEncoder.withIndent('  ').convert(exportPlan(pWorksite)),
    pMime: 'application/json',
  );
}

/// Étages et pièces pour Home Assistant, partagés comme fichier JSON (voir docs/home-assistant.md).
Future<void> exportHomeAssistantFile(Worksite pWorksite) async {
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile(
    'home_assistant_$vName.json',
    const JsonEncoder.withIndent('  ').convert(exportHomeAssistant(pWorksite)),
    pMime: 'application/json',
  );
}

/// Maison en 3D au format glTF, partagée comme fichier .gltf (Blender, visualiseurs web).
Future<void> exportGltfFile(Worksite pWorksite) async {
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile(
    'maison_$vName.gltf',
    jsonEncode(buildGltf(houseRooms(pWorksite))),
    pMime: 'model/gltf+json',
  );
}

/// Plan de la maison en DXF, pour un logiciel de dessin, envoyé par le partage du téléphone.
Future<void> exportDxfFile(Worksite pWorksite) async {
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile('plan_$vName.dxf', buildDxf(houseRooms(pWorksite)), pMime: 'application/dxf');
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
    // Projet partagé seul : ses photos sont dans le fichier, à recopier sur ce téléphone
    if (isProjectBundle(vContent)) {
      vContent = await unpackProject(vContent);
    }
    final vWorksites = WorksiteStore.decode(vContent);
    // Stock d'une sauvegarde complète : seuls les articles absents de ce téléphone sont ajoutés
    final vStock = WorksiteStore.decodeWorkshop(vContent);
    if (vStock != null) {
      for (final vItem in vStock) {
        if (!aWorkshop.items.any((pOwned) => pOwned.id == vItem.id)) {
          await aWorkshop.upsert(vItem);
        }
      }
    }
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
