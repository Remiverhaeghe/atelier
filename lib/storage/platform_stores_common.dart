import '../logic/worksite.dart';
import '../support/crash_log.dart';
import '../ui/reminder_alarm.dart';
import 'backups.dart';
import 'settings_store.dart';
import 'worksite_store.dart';

/// Tout ce que le démarrage ouvre selon la plate-forme.
typedef PlatformStores = ({
  /// Journal des plantages ; null quand il n'y a pas de fichier où l'écrire (web).
  CrashLog? crashLog,
  Backups? backups,
  WorksiteStorage worksites,
  SettingsStorage settings,
  ReminderAlarm alarm,

  /// Appelé à chaque changement des chantiers (widget d'écran d'accueil sur Android).
  void Function(List<Worksite> pWorksites) onChange,
});
