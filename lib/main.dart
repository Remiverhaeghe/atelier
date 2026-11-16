import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'state/worksites_controller.dart';
import 'storage/worksite_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final vFolder = await getApplicationDocumentsDirectory();
  final vController = WorksitesController(WorksiteStore(File('${vFolder.path}/chantiers.json')));
  runApp(AtelierApp(controller: vController));
  await vController.load();
}
