import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'state/worksites_controller.dart';
import 'support/crash_log.dart';
import 'ui/worksites_screen.dart';

/// Application Atelier : thème, langue et premier écran.
class AtelierApp extends StatelessWidget {
  const AtelierApp({super.key, required this.controller, this.crashLog});

  final WorksitesController controller;
  final CrashLog? crashLog;

  @override
  Widget build(BuildContext context) {
    // Vert de chantier, contrasté en clair comme en sombre
    const vSeed = Color(0xFF2E6B3A);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (pContext) => AppLocalizations.of(pContext).appTitle,
      // Cibles tactiles larges : l'application s'utilise sur un chantier, parfois avec des gants
      theme: ThemeData(
        colorSchemeSeed: vSeed,
        useMaterial3: true,
        visualDensity: VisualDensity.comfortable,
      ),
      darkTheme: ThemeData(colorSchemeSeed: vSeed, brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: WorksitesScreen(controller: controller, crashLog: crashLog),
    );
  }
}
