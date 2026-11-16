import 'dart:convert';
import 'dart:io';

import '../logic/app_settings.dart';

/// Lecture et écriture des réglages ; remplacée par une version en mémoire dans les tests.
abstract interface class SettingsStorage {
  Future<AppSettings> load();

  Future<void> save(AppSettings pSettings);
}

/// Réglages dans un petit fichier JSON, à côté des chantiers.
class SettingsFileStore implements SettingsStorage {
  SettingsFileStore(this.file);

  final File file;

  @override
  Future<AppSettings> load() async {
    if (!file.existsSync()) {
      return const AppSettings();
    }
    try {
      return AppSettings.fromJson(jsonDecode(await file.readAsString()) as Map<String, Object?>);
    } on FormatException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings pSettings) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(pSettings.toJson()), flush: true);
  }
}
