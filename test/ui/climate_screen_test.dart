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
          log: ClimateLog(
            days: const [],
            worksOn: DateTime(2026, 11, 20),
          ),
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
}
