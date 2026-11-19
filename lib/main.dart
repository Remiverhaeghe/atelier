import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'state/settings_controller.dart';
import 'state/worksites_controller.dart';
import 'storage/platform_stores.dart';
import 'ui/reminder_alarm.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fichiers sur le téléphone, stockage du navigateur pour la version web
  final vStores = await openPlatformStores();
  final vCrashLog = vStores.crashLog;
  // Plantages notés dans un journal local, jamais envoyés : l'utilisateur le partage s'il le veut.
  FlutterError.onError = (pDetails) {
    FlutterError.presentError(pDetails);
    vCrashLog?.record(pDetails.exception, pDetails.stack);
  };
  PlatformDispatcher.instance.onError = (pError, pStack) {
    vCrashLog?.record(pError, pStack);

    return true;
  };
  aReminderAlarm = vStores.alarm;
  final vController = WorksitesController(vStores.worksites);
  // Réglages lus avant le premier affichage : pas d'éclair blanc si le thème sombre est choisi
  final vSettings = SettingsController(vStores.settings);
  await vSettings.load();
  runApp(
    AtelierApp(
      controller: vController,
      crashLog: vCrashLog,
      backups: vStores.backups,
      settings: vSettings,
    ),
  );
  // Le widget d'écran d'accueil suit chaque changement du chantier
  vController.addListener(() => vStores.onChange(vController.worksites));
  await vController.load();
}
