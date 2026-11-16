import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'ui/worksites_screen.dart';

/// Application Atelier : thème, langue et premier écran.
class AtelierApp extends StatelessWidget {
  const AtelierApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Vert de chantier, contrasté en clair comme en sombre
    const vSeed = Color(0xFF2E6B3A);

    return MaterialApp(
      onGenerateTitle: (pContext) => AppLocalizations.of(pContext).appTitle,
      theme: ThemeData(colorSchemeSeed: vSeed, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: vSeed, brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WorksitesScreen(),
    );
  }
}
