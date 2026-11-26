import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/climate_sensors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

String _csv(double pHumidity) => [
  'Timestamp,Temperature_Celsius(°C),Relative_Humidity(%)',
  for (var vHour = 0; vHour < 48; vHour += 12)
    '${DateTime(2026, 12, 1).add(Duration(hours: vHour)).toIso8601String()},20,$pHumidity',
].join('\n');

void main() {
  testWidgets('chaque fichier va dans sa pièce, le reste se range à la main', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = const [
        Worksite(
          id: 'w',
          name: 'Maison',
          rooms: [
            Room(id: 'sdb', name: 'Salle de bain'),
            Room(id: 'cuis', name: 'Cuisine'),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    final vFiles = <SensorFile>[
      (name: 'Salle de bain.csv', text: _csv(78)),
      (name: 'Couloir.csv', text: _csv(50)),
      (name: 'abime.csv', text: 'rien de lisible'),
    ];
    await pTester.pumpWidget(
      localized(
        ClimateSensorsScreen(
          controller: vController,
          worksiteId: 'w',
          pickFile: () async => vFiles.removeAt(0),
        ),
      ),
    );

    await pTester.tap(find.text('Ajouter un fichier de capteur'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('2 jours ajoutés à « Salle de bain »'), findsOneWidget);
    expect(vController.worksite('w')!.rooms.first.climate.days.first.humidity, 78);

    await pTester.tap(find.text('Ajouter un fichier de capteur'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Couloir : aucune pièce de ce nom'), findsOneWidget);

    await pTester.tap(find.byTooltip('Choisir la pièce'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Cuisine').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Couloir : aucune pièce'), findsNothing);
    expect(find.textContaining('2 jours ajoutés à « Cuisine »'), findsOneWidget);
    expect(vController.worksite('w')!.rooms.last.climate.days, hasLength(2));

    await pTester.tap(find.text('Ajouter un fichier de capteur'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Fichier illisible'), findsOneWidget);
  });
}
