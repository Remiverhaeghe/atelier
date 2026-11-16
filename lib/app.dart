import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'state/worksites_controller.dart';
import 'storage/backups.dart';
import 'support/crash_log.dart';
import 'ui/theme.dart';
import 'ui/worksites_screen.dart';

/// Application Atelier : thème, langue et premier écran.
class AtelierApp extends StatelessWidget {
  const AtelierApp({super.key, required this.controller, this.crashLog, this.backups});

  final WorksitesController controller;
  final CrashLog? crashLog;
  final Backups? backups;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (pContext) => AppLocalizations.of(pContext).appTitle,
      theme: atelierTheme(Brightness.light),
      darkTheme: atelierTheme(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: WorksitesScreen(controller: controller, crashLog: crashLog, backups: backups),
    );
  }
}
