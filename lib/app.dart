import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'logic/app_settings.dart';
import 'logic/units.dart';
import 'state/settings_controller.dart';
import 'state/worksites_controller.dart';
import 'storage/backups.dart';
import 'support/crash_log.dart';
import 'ui/theme.dart';
import 'ui/worksites_screen.dart';

/// Application Atelier : thème, langue et premier écran.
class AtelierApp extends StatelessWidget {
  const AtelierApp({
    super.key,
    required this.controller,
    this.crashLog,
    this.backups,
    this.settings,
  });

  final WorksitesController controller;
  final CrashLog? crashLog;
  final Backups? backups;

  /// Thème et taille du texte choisis dans « À propos » ; ceux du téléphone sans lui.
  final SettingsController? settings;

  @override
  Widget build(BuildContext context) {
    final vSettings = settings;
    if (vSettings == null) {
      return _app(const AppSettings());
    }

    return ListenableBuilder(listenable: vSettings, builder: (_, _) => _app(vSettings.settings));
  }

  Widget _app(AppSettings pSettings) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (pContext) => AppLocalizations.of(pContext).appTitle,
      theme: atelierTheme(Brightness.light),
      darkTheme: atelierTheme(Brightness.dark),
      themeMode: switch (pSettings.theme) {
        ThemeChoice.system => ThemeMode.system,
        ThemeChoice.light => ThemeMode.light,
        ThemeChoice.dark => ThemeMode.dark,
      },
      locale: switch (pSettings.language) {
        LanguageChoice.system => null,
        LanguageChoice.french => const Locale('fr'),
        LanguageChoice.english => const Locale('en'),
      },
      // La taille choisie s'ajoute à celle du téléphone
      builder: (pContext, pChild) {
        // Les nombres suivent la langue affichée : 2,5 en français, 2.5 en anglais
        aDecimalSeparator = Localizations.localeOf(pContext).languageCode == 'fr' ? ',' : '.';

        return MediaQuery(
        data: MediaQuery.of(pContext).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(pContext).scale(1) * pSettings.textScale,
          ),
        ),
        child: pChild!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: WorksitesScreen(
        controller: controller,
        crashLog: crashLog,
        backups: backups,
        settings: settings,
      ),
    );
  }
}
