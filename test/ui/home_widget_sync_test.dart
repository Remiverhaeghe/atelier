import 'package:atelier/l10n/gen/app_localizations_fr.dart';
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
}
