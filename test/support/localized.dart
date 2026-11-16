import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran isolé avec les textes français, pour les tests d'écran.
Widget localized(Widget pChild) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: pChild),
);

/// Liste verticale de l'écran : les champs de saisie et les onglets défilent aussi.
Finder verticalList() => find
    .byWidgetPredicate((pWidget) => pWidget is Scrollable && pWidget.axisDirection == AxisDirection.down)
    .first;
