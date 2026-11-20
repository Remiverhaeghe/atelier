import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/state/settings_controller.dart';
import 'package:atelier/storage/settings_store.dart';

/// Réglages en mémoire.
class MemorySettings implements SettingsStorage {
  AppSettings saved = const AppSettings();

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings pSettings) async => saved = pSettings;
}

/// Réglages qui forcent le français : sur émulateur, la langue du téléphone simulé ne suffit pas.
Future<SettingsController> frenchSettings() async {
  final rSettings = SettingsController(
    MemorySettings()..saved = const AppSettings(language: LanguageChoice.french),
  );
  await rSettings.load();

  return rSettings;
}
