import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

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

/// Langue du widget : celle du téléphone si l'appli la connaît, sinon le français.
Locale widgetLocale(List<Locale> pLocales) {
  final vKnown = AppLocalizations.supportedLocales.map((pLocale) => pLocale.languageCode);
  final rLocale = pLocales
      .map((pLocale) => Locale(pLocale.languageCode))
      .firstWhere(
        (pLocale) => vKnown.contains(pLocale.languageCode),
        orElse: () => const Locale('fr'),
      );

  return rLocale;
}

/// Fichier lu par le widget Android (`ObjectifWidget.kt`), dans le dossier de l'appli.
const homeWidgetFile = 'widget.json';

/// Écrit les lignes du widget ; Android les relit toutes les 30 minutes ou quand on le pose.
Future<void> publishHomeWidget(Directory pFolder, List<Worksite> pWorksites, DateTime pNow) async {
  final vLines = homeWidgetLines(
    lookupAppLocalizations(widgetLocale(PlatformDispatcher.instance.locales)),
    homeSummary(pWorksites, pNow),
  );
  final vFile = File('${pFolder.path}/$homeWidgetFile');
  final vTemp = File('${vFile.path}.tmp');
  try {
    // Écrit à côté puis renommé : le widget ne lit jamais un fichier à moitié écrit
    await vTemp.writeAsString(
      jsonEncode({'title': vLines.title, 'goal': vLines.goal, 'wait': vLines.wait}),
    );
    await vTemp.rename(vFile.path);
  } on FileSystemException catch (pError) {
    developer.log('Widget non mis à jour : ${pError.message}', name: 'atelier');
  }
}
