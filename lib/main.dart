import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'state/settings_controller.dart';
import 'state/workshop_controller.dart';
import 'state/worksites_controller.dart';
import 'storage/backups.dart';
import 'storage/settings_store.dart';
import 'storage/workshop_store.dart';
import 'storage/worksite_store.dart';
import 'support/crash_log.dart';
import 'ui/home_widget_sync.dart';
import 'ui/reminder_alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vFolder = await getApplicationDocumentsDirectory();
  final vCrashLog = CrashLog(File('${vFolder.path}/plantages.txt'));
  // Plantages notés dans un journal local, jamais envoyés : l'utilisateur le partage s'il le veut.
  FlutterError.onError = (pDetails) {
    FlutterError.presentError(pDetails);
    vCrashLog.record(pDetails.exception, pDetails.stack);
  };
  PlatformDispatcher.instance.onError = (pError, pStack) {
    vCrashLog.record(pError, pStack);

    return true;
  };
  aReminderAlarm = LocalReminderAlarm();
  final vBackups = Backups(Directory('${vFolder.path}/sauvegardes'));
  final vController = WorksitesController(
    WorksiteStore(File('${vFolder.path}/chantiers.json'), backups: vBackups),
  );
  // Réglages lus avant le premier affichage : pas d'éclair blanc si le thème sombre est choisi
  final vSettings = SettingsController(SettingsFileStore(File('${vFolder.path}/reglages.json')));
  await vSettings.load();
  aWorkshop = WorkshopController(WorkshopFileStore(File('${vFolder.path}/atelier.json')));
  await aWorkshop.load();
  runApp(
    AtelierApp(
      controller: vController,
      crashLog: vCrashLog,
      backups: vBackups,
      settings: vSettings,
    ),
  );
  // Le widget d'écran d'accueil suit chaque changement du chantier
  vController.addListener(() => publishHomeWidget(vFolder, vController.worksites, DateTime.now()));
  await vController.load();
}
