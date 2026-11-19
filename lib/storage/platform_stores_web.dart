import 'dart:convert';

import 'package:web/web.dart' as web;

import '../logic/app_settings.dart';
import '../logic/worksite.dart';
import '../ui/reminder_alarm.dart';
import 'platform_stores_common.dart';
import 'settings_store.dart';
import 'worksite_store.dart';

export 'platform_stores_common.dart';

/// Clés du stockage local du navigateur.
const worksitesKey = 'atelier.chantiers';
const settingsKey = 'atelier.reglages';

/// Version web : les données restent dans le navigateur, sur l'appareil, jamais envoyées.
Future<PlatformStores> openPlatformStores() async {
  final rStores = (
    // Pas de fichier sur le web : pas de journal des plantages
    crashLog: null,
    // Pas de sauvegardes datées dans le navigateur : l'export de chantier reste possible
    backups: null,
    worksites: BrowserWorksiteStore(),
    settings: BrowserSettingsStore(),
    // Pas de notification programmée sur le web
    alarm: const SilentAlarm(),
    onChange: (List<Worksite> _) {},
  );

  return rStores;
}

/// Chantiers dans le stockage local du navigateur, au même format que le fichier du téléphone.
class BrowserWorksiteStore implements WorksiteStorage {
  @override
  Future<List<Worksite>> load() async {
    final vText = web.window.localStorage.getItem(worksitesKey);
    if (vText == null) {
      return const [];
    }
    final rWorksites = WorksiteStore.decode(vText);

    return rWorksites;
  }

  @override
  Future<void> save(List<Worksite> pWorksites) async {
    web.window.localStorage.setItem(worksitesKey, WorksiteStore.encode(pWorksites));
  }
}

/// Réglages dans le stockage local du navigateur.
class BrowserSettingsStore implements SettingsStorage {
  @override
  Future<AppSettings> load() async {
    final vText = web.window.localStorage.getItem(settingsKey);
    if (vText == null) {
      return const AppSettings();
    }
    try {
      return AppSettings.fromJson(jsonDecode(vText) as Map<String, Object?>);
    } on FormatException {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings pSettings) async {
    web.window.localStorage.setItem(settingsKey, jsonEncode(pSettings.toJson()));
  }
}
