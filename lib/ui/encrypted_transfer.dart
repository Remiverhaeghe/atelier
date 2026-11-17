import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/encrypted_backup.dart';
import '../logic/worksite.dart';
import '../storage/worksite_store.dart';

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
  final vEnvelope = await encryptBackup(WorksiteStore.encode(pWorksites), vPassword);
  final vFolder = await getTemporaryDirectory();
  final vDate = pDay.toIso8601String().substring(0, 10);
  final vFile = File('${vFolder.path}/atelier_sauvegarde_$vDate.atelier');
  await vFile.writeAsString(vEnvelope);
  await SharePlus.instance.share(ShareParams(files: [XFile(vFile.path)]));
}
