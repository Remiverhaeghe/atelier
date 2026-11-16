import 'package:flutter/foundation.dart';

import '../logic/app_settings.dart';
import '../storage/settings_store.dart';

/// Réglages d'affichage en cours, enregistrés à chaque changement.
class SettingsController extends ChangeNotifier {
  SettingsController(this.store);

  final SettingsStorage store;
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await store.load();
    notifyListeners();
  }

  Future<void> update(AppSettings pSettings) async {
    _settings = pSettings;
    notifyListeners();
    await store.save(pSettings);
  }
}
