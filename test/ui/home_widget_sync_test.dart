import 'dart:convert';
import 'dart:io';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/home_widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vText = AppLocalizationsFr();

  test('lignes du widget selon le résumé', () {
    expect(homeWidgetLines(vText, null).goal, 'Créez un chantier pour suivre l\'objectif du jour');

    final vLines = homeWidgetLines(vText, (
      worksite: 'Maison',
      done: 2,
      total: 3,
      nextWaitHours: 1,
    ));
    expect(vLines.title, 'Maison');
    expect(vLines.goal, 'Objectif du jour : 2 sur 3');
    expect(vLines.wait, 'Prochaine attente finie dans 1 heure');

    final vIdle = homeWidgetLines(vText, (
      worksite: 'Maison',
      done: 0,
      total: 0,
      nextWaitHours: null,
    ));
    expect((vIdle.goal, vIdle.wait), ('Pas d\'objectif aujourd\'hui', ''));
  });

  test('le fichier lu par le widget Android', () async {
    final vFolder = await Directory.systemTemp.createTemp('widget');
    addTearDown(() => vFolder.delete(recursive: true));
    await publishHomeWidget(vFolder, const [
      Worksite(id: 'w', name: 'Maison'),
    ], DateTime(2026, 11, 17));
    final vData = jsonDecode(File('${vFolder.path}/$homeWidgetFile').readAsStringSync()) as Map;
    expect(vData['title'], 'Maison');
    expect(vData['goal'], 'Pas d\'objectif aujourd\'hui');

    // Dossier disparu : rien ne plante
    await publishHomeWidget(Directory('${vFolder.path}/absent'), const [], DateTime(2026));
  });
}
