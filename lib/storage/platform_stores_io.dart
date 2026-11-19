import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../support/crash_log.dart';
import '../ui/home_widget_sync.dart';
import '../ui/reminder_alarm.dart';
import 'backups.dart';
import 'platform_stores_common.dart';
import 'settings_store.dart';
import 'worksite_store.dart';

export 'platform_stores_common.dart';

/// Version téléphone : des fichiers dans le dossier de l'application.
Future<PlatformStores> openPlatformStores() async {
  final vFolder = await getApplicationDocumentsDirectory();
  final vBackups = Backups(Directory('${vFolder.path}/sauvegardes'));
  final rStores = (
    crashLog: CrashLog(File('${vFolder.path}/plantages.txt')),
    backups: vBackups,
    worksites: WorksiteStore(File('${vFolder.path}/chantiers.json'), backups: vBackups),
    settings: SettingsFileStore(File('${vFolder.path}/reglages.json')),
    alarm: LocalReminderAlarm(),
    onChange: (pWorksites) => publishHomeWidget(vFolder, pWorksites, DateTime.now()),
  );

  return rStores;
}
