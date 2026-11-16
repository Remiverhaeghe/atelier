import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../state/worksites_controller.dart';
import '../storage/backups.dart';
import '../storage/worksite_store.dart';

/// Sauvegardes quotidiennes, à restaurer en un geste après confirmation.
class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key, required this.backups, required this.controller});

  final Backups backups;
  final WorksitesController controller;

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  Future<void> _restore(Backup pBackup) async {
    final vText = AppLocalizations.of(context);
    final vMessenger = ScaffoldMessenger.of(context);
    final vSure = await showDialog<bool>(
      context: context,
      builder: (pContext) => AlertDialog(
        title: Text(vText.backupRestoreTitle),
        content: Text(vText.backupRestoreConfirm(pBackup.day)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(pContext, false), child: Text(vText.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(pContext, true),
            child: Text(vText.backupRestore),
          ),
        ],
      ),
    );
    if (vSure != true) {
      return;
    }
    try {
      await widget.controller.replaceAll(WorksiteStore.decode(await pBackup.file.readAsString()));
      vMessenger.showSnackBar(SnackBar(content: Text(vText.backupRestored(pBackup.day))));
    } on FormatException {
      vMessenger.showSnackBar(SnackBar(content: Text(vText.importFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vList = widget.backups.list();

    return Scaffold(
      appBar: AppBar(title: Text(vText.backupsTitle)),
      body: ListView(
        children: [
          ListTile(subtitle: Text(vText.backupsHelp(widget.backups.keep))),
          if (vList.isEmpty) ListTile(title: Text(vText.backupsEmpty)),
          for (final vBackup in vList)
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(vBackup.day),
                trailing: TextButton(
                  onPressed: () => _restore(vBackup),
                  child: Text(vText.backupRestore),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
