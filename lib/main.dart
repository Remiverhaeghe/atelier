import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'state/worksites_controller.dart';
import 'storage/worksite_store.dart';
import 'support/crash_log.dart';

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
  final vController = WorksitesController(WorksiteStore(File('${vFolder.path}/chantiers.json')));
  runApp(AtelierApp(controller: vController, crashLog: vCrashLog));
  await vController.load();
}
