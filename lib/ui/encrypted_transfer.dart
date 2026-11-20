import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/encrypted_backup.dart';
import '../logic/project_bundle.dart';
import '../logic/worksite.dart';
import '../state/workshop_controller.dart';
import '../storage/worksite_store.dart';
import '../storage/photo_store.dart';

import 'share_file.dart';

/// Mot de passe de la sauvegarde ; avec [pConfirm], demandé deux fois pour éviter une faute.
Future<String?> askBackupPassword(BuildContext pContext, {bool pConfirm = false}) {
  final vText = AppLocalizations.of(pContext);
  // Pas libérés à la fermeture : le dialogue les utilise encore pendant son animation
  final vFirst = TextEditingController();
  final vSecond = TextEditingController();
  String? vError;

  return showDialog<String>(
    context: pContext,
    builder: (pDialog) => StatefulBuilder(
      builder: (pInner, pSetState) => AlertDialog(
        title: Text(vText.backupPasswordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vText.backupPasswordHelp),
            TextField(
              controller: vFirst,
              obscureText: true,
              decoration: InputDecoration(labelText: vText.backupPassword),
            ),
            if (pConfirm)
              TextField(
                controller: vSecond,
                obscureText: true,
                decoration: InputDecoration(labelText: vText.backupPasswordAgain),
              ),
            if (vError != null)
              Text(vError!, style: TextStyle(color: Theme.of(pInner).colorScheme.error)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.cancel)),
          FilledButton(
            onPressed: () {
              if (pConfirm && vFirst.text.length < minPasswordLength) {
                pSetState(() => vError = vText.backupPasswordShort(minPasswordLength));
              } else if (pConfirm && vFirst.text != vSecond.text) {
                pSetState(() => vError = vText.backupPasswordMismatch);
              } else {
                Navigator.pop(pDialog, vFirst.text);
              }
            },
            child: Text(vText.backupPasswordOk),
          ),
        ],
      ),
    ),
  );
}

/// Tous les chantiers chiffrés dans un fichier daté, à envoyer hors du téléphone.
Future<void> exportEncryptedBackup(
  BuildContext pContext,
  List<Worksite> pWorksites,
  DateTime pDay,
) async {
  final vPassword = await askBackupPassword(pContext, pConfirm: true);
  if (vPassword == null) {
    return;
  }
  final vEnvelope = await encryptBackup(
    WorksiteStore.encode(pWorksites, pWorkshop: aWorkshop.items),
    vPassword,
  );
  final vDate = pDay.toIso8601String().substring(0, 10);
  await shareTextFile(
    'atelier_sauvegarde_$vDate.atelier',
    vEnvelope,
    pMime: 'application/octet-stream',
  );
}

/// Un seul chantier, avec ses croquis, son débit, ses notes et ses photos, chiffré dans un
/// fichier à partager (autre téléphone, proche qui aide au chantier).
Future<void> exportEncryptedProject(BuildContext pContext, Worksite pWorksite) async {
  final vPassword = await askBackupPassword(pContext, pConfirm: true);
  if (vPassword == null) {
    return;
  }
  final vJson = WorksiteStore.encode([pWorksite]);
  final vFiles = <String, List<int>>{};
  for (final vPath in attachedPaths(jsonDecode(vJson))) {
    // Une photo effacée du téléphone ne bloque pas le partage du reste
    final vBytes = readPhoto(vPath);
    if (vBytes != null) {
      vFiles[vPath] = vBytes;
    }
  }
  final vEnvelope = await encryptBackup(encodeProjectBundle(vJson, vFiles), vPassword);
  final vName = pWorksite.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  await shareTextFile(
    'atelier_projet_$vName.atelier',
    vEnvelope,
    pMime: 'application/octet-stream',
  );
}

/// Recopie les photos d'un projet reçu dans le dossier de l'application et renvoie le JSON
/// des chantiers, aux nouveaux chemins.
Future<String> unpackProject(String pContent) async {
  final vBundle = decodeProjectBundle(pContent);
  final vStamp = '${DateTime.now().millisecondsSinceEpoch}';
  final vMoves = <String, String>{};
  for (final vEntry in vBundle.files.entries) {
    vMoves[vEntry.key] = await keepPhoto(importedName(vEntry.key, vStamp), vEntry.value);
  }
  final rJson = jsonEncode(relocatePaths(vBundle.worksites, vMoves));

  return rJson;
}
