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
                builder: (_) => ClimateScreen(canAddTouchUps: true, pickFile: () async => dampExport()),
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
}
