import 'dart:developer' as developer;
import 'dart:ui' show Locale;

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/home_summary.dart';
import '../logic/worksite.dart';

/// Lignes du widget d'écran d'accueil : titre, objectif du jour et prochaine attente.
({String title, String goal, String wait}) homeWidgetLines(
  AppLocalizations pText,
  HomeSummary? pSummary,
) {
  if (pSummary == null) {
    return (title: pText.appTitle, goal: pText.widgetNoWorksite, wait: '');
  }
  final rLines = (
    title: pSummary.worksite,
    goal: pSummary.total == 0
        ? pText.widgetNoGoal
        : pText.widgetGoal(pSummary.done, pSummary.total),
    wait: pSummary.nextWaitHours == null ? '' : pText.widgetWait(pSummary.nextWaitHours!),
  );

  return rLines;
}

/// Écrit les lignes pour le widget Android et lui demande de se redessiner.
Future<void> publishHomeWidget(List<Worksite> pWorksites, DateTime pNow) async {
  final vLines = homeWidgetLines(
    lookupAppLocalizations(const Locale('fr')),
    homeSummary(pWorksites, pNow),
  );
  try {
    await HomeWidget.saveWidgetData<String>('title', vLines.title);
    await HomeWidget.saveWidgetData<String>('goal', vLines.goal);
    await HomeWidget.saveWidgetData<String>('wait', vLines.wait);
    await HomeWidget.updateWidget(androidName: 'ObjectifWidget');
  } on PlatformException catch (pError) {
    // Sans widget posé ou hors d'Android : rien à mettre à jour
    developer.log('Widget non mis à jour : ${pError.code}', name: 'atelier');
  } on MissingPluginException {
    developer.log('Widget absent sur cette plateforme', name: 'atelier');
  }
}
