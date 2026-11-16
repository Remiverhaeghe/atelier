import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' show Locale;

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

/// Fichier lu par le widget Android (`ObjectifWidget.kt`), dans le dossier de l'appli.
const homeWidgetFile = 'widget.json';

/// Écrit les lignes du widget ; Android les relit toutes les 30 minutes ou quand on le pose.
Future<void> publishHomeWidget(
  Directory pFolder,
  List<Worksite> pWorksites,
  DateTime pNow,
) async {
  final vLines = homeWidgetLines(
    lookupAppLocalizations(const Locale('fr')),
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
