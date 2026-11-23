import 'package:atelier/logic/climate_history.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/climate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

/// Export fictif : salle d'eau à 75 % d'humidité tout le temps.
String dampExport() => [
  'Timestamp,Temperature_Celsius(°C),Relative_Humidity(%)',
  for (var vHour = 0; vHour < 48; vHour++)
    '${DateTime(2026, 12, 1).add(Duration(hours: vHour)).toIso8601String()},20,75',
].join('\n');

void main() {
  testWidgets('relevés humides : constat, conseil et reprise ajoutée', (pTester) async {
    tallScreen(pTester);
    List<TouchUp>? vTouchUps;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vTouchUps = await Navigator.push(
              pContext,
              MaterialPageRoute<List<TouchUp>>(
                builder: (_) =>
                    ClimateScreen(canAddTouchUps: true, pickFile: () async => dampExport()),
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Choisir le fichier des relevés'));
    await pTester.pumpAndSettle();

    expect(find.text('Air trop humide'), findsOneWidget);
    expect(find.textContaining('100 % du temps au-dessus de 70 %'), findsOneWidget);

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Ajouter 1 constat aux reprises'));
    await pTester.pumpAndSettle();

    expect(vTouchUps!.single.label, 'Air trop humide');
    expect(vTouchUps!.single.note, contains('VMC'));
  });

  testWidgets('fichier sans les bonnes colonnes : message clair', (pTester) async {
    await pTester.pumpWidget(
      localized(ClimateScreen(pickFile: () async => 'Date,Temp\n2026-12-01,20\n')),
    );
    await pTester.tap(find.text('Choisir le fichier des relevés'));
    await pTester.pumpAndSettle();

    expect(find.textContaining('Fichier illisible'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('chaque import s\'ajoute au suivi de la pièce, avec la date des travaux', (
    pTester,
  ) async {
    tallScreen(pTester);
    ClimateLog? vKept;
    await pTester.pumpWidget(
      localized(
        ClimateScreen(
          canAddTouchUps: true,
          pickFile: () async => dampExport(),
          log: ClimateLog(days: const [], worksOn: DateTime(2026, 11, 20)),
          onLog: (pLog) => vKept = pLog,
        ),
      ),
    );
    await pTester.tap(find.text('Choisir le fichier des relevés'));
    await pTester.pumpAndSettle();

    expect(vKept!.days, hasLength(2));
    expect(vKept!.days.first.humidity, 75);
    expect(find.text('Humidité jour après jour'), findsOneWidget);
    expect(find.text('2 jours suivis, du 01/12/2026 au 02/12/2026'), findsOneWidget);
    expect(find.text('Travaux le 20/11/2026'), findsOneWidget);
    expect(find.textContaining("d'avant et d'après les travaux"), findsOneWidget);

    await pTester.tap(find.text('Retirer la date'));
    await pTester.pumpAndSettle();
    expect(vKept!.worksOn, isNull);
    expect(find.text('Date des travaux'), findsOneWidget);
  });

  group('comparer deux pièces', () {
    ClimateLog suivi(double pHumidity, {int pFrom = 1}) => ClimateLog(
      days: [
        for (var vDay = pFrom; vDay < pFrom + 3; vDay++)
          ClimateDay(
            day: DateTime(2026, 12, vDay),
            tempC: 19,
            humidity: pHumidity,
            maxHumidity: pHumidity + 5,
            count: 24,
          ),
      ],
    );

    Widget ecran(List<NamedClimate> pOthers) =>
        localized(ClimateScreen(log: suivi(50), onLog: (_) {}, others: pOthers));

    testWidgets('sans autre pièce suivie, le bouton n\'est pas proposé', (pTester) async {
      tallScreen(pTester);
      await pTester.pumpWidget(ecran(const []));

      expect(find.text('Comparer avec une autre pièce'), findsNothing);
    });

    testWidgets('une pièce choisie : résumés et pièce la plus sèche', (pTester) async {
      tallScreen(pTester);
      await pTester.pumpWidget(ecran([(name: 'Salle de bain', log: suivi(72))]));
      await pTester.tap(find.text('Comparer avec une autre pièce'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('Salle de bain'));
      await pTester.pumpAndSettle();

      expect(find.textContaining('Cette pièce : 50 % en moyenne'), findsOneWidget);
      expect(find.textContaining('Salle de bain : 72 % en moyenne'), findsOneWidget);
      expect(
        find.textContaining('Cette pièce : plus sèche de 22 points sur les 3 jours'),
        findsOneWidget,
      );

      await pTester.tap(find.text('Retirer la comparaison'));
      await pTester.pumpAndSettle();
      expect(find.textContaining('plus sèche de'), findsNothing);
      expect(find.text('Comparer avec une autre pièce'), findsOneWidget);
    });

    testWidgets('l\'autre pièce plus sèche', (pTester) async {
      tallScreen(pTester);
      await pTester.pumpWidget(ecran([(name: 'Chambre', log: suivi(30))]));
      await pTester.tap(find.text('Comparer avec une autre pièce'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('Chambre'));
      await pTester.pumpAndSettle();

      expect(find.textContaining('Chambre : plus sèche de 20 points'), findsOneWidget);
    });

    testWidgets('deux pièces à moins de trois points : même humidité', (pTester) async {
      tallScreen(pTester);
      await pTester.pumpWidget(ecran([(name: 'Bureau', log: suivi(51))]));
      await pTester.tap(find.text('Comparer avec une autre pièce'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('Bureau'));
      await pTester.pumpAndSettle();

      expect(find.textContaining('Même humidité dans les deux pièces'), findsOneWidget);
    });

    testWidgets('sans jour en commun : message clair, pas de chiffres', (pTester) async {
      tallScreen(pTester);
      await pTester.pumpWidget(ecran([(name: 'Cave', log: suivi(80, pFrom: 20))]));
      await pTester.tap(find.text('Comparer avec une autre pièce'));
      await pTester.pumpAndSettle();
      await pTester.tap(find.text('Cave'));
      await pTester.pumpAndSettle();

      expect(find.textContaining('aucun jour relevé en même temps'), findsOneWidget);
      expect(find.textContaining('plus sèche de'), findsNothing);
    });
  });
}
