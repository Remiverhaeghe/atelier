import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Écran isolé avec les textes français, pour les tests d'écran.
Widget localized(Widget pChild) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: pChild),
);
