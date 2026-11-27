import 'dart:convert';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/door_calculator.dart';
import 'package:atelier/ui/floor_prep_calculator.dart';
import 'package:atelier/ui/high_paint_calculator.dart';
import 'package:atelier/ui/memories_pdf.dart';
import 'package:atelier/ui/memories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('sol : chape ciment, sous-couche, joints et séchage', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const FloorPrepCalculator()));
    expect(find.text('20 m² à couvrir'), findsOneWidget);
    expect(find.text('30 sacs de mortier de chape de 35 kg'), findsNothing);
    expect(find.textContaining('60 sacs de mortier de chape'), findsOneWidget);
    expect(find.textContaining('environ 35 jours'), findsOneWidget);
    expect(find.textContaining('2 rouleaux de 15 m²'), findsOneWidget);
    expect(find.text('Un joint de dilatation à chaque seuil de porte.'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Humidité mesurée (%), si vous l\'avez'),
      '2,5',
    );
    await pTester.pump();
    expect(find.textContaining('attendez encore'), findsOneWidget);

    await pTester.tap(find.text('Sèche'));
    await pTester.pump();
    expect(find.text('Chape sèche : la pose peut suivre tout de suite.'), findsOneWidget);
    expect(find.textContaining('plaques de chape sèche'), findsOneWidget);
    expect(find.text('Mesure sous le seuil : la pose est possible.'), findsOneWidget);

    await pTester.tap(find.text('Fluide anhydrite'));
    await pTester.pump();
    expect(find.text('1,05 m³ à faire couler par un chapiste'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur de chape (mm)'), '20');
    await pTester.pump();
    expect(find.textContaining('30 mm au moins'), findsOneWidget);
  });

  testWidgets('porte : sens trouvé, recoupe sous la porte et poignée', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const DoorCalculator()));
    expect(find.text('C\'est une porte poussant droit'), findsOneWidget);
    await scrollToFirst(pTester, find.text('Je pousse la porte pour l\'ouvrir'));
    await pTester.tap(find.text('Je pousse la porte pour l\'ouvrir'));
    await pTester.pump();
    expect(find.text('C\'est une porte poussant gauche'), findsOneWidget);

    expect(find.text('Le jeu sous la porte suffit encore.'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Épaisseur du nouveau sol (mm)'), '14');
    await pTester.pump();
    expect(find.text('Recouper 14 mm sous la porte pour garder 1 cm d\'air'), findsOneWidget);

    expect(find.text('Poignée à une hauteur confortable.'), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Hauteur de la poignée depuis le sol fini (cm)'),
      '80',
    );
    await pTester.pump();
    expect(find.textContaining('entre 90 cm et 130 cm du sol'), findsOneWidget);
  });

  testWidgets('grande hauteur : manche, escabeau, échafaudage et ordre de travail', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const HighPaintCalculator()));
    expect(
      find.text('Manche télescopique de 3 m et escabeau pour découper les angles'),
      findsOneWidget,
    );
    expect(find.text('Murs : 76 m², 15,2 L, 2 pots de 10 L'), findsOneWidget);
    expect(find.text('Plafond : 16 m², 3,2 L, 1 pot de 10 L'), findsOneWidget);
    expect(find.textContaining('Avancer l\'échafaudage'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur du mur (cm)'), '650');
    await pTester.pump();
    expect(find.text('Échafaudage roulant, à déplacer le long du mur'), findsOneWidget);
    expect(find.textContaining('roues bloquées'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur du mur (cm)'), '300');
    await pTester.pump();
    expect(find.text('Rouleau sur manche télescopique de 1 m'), findsOneWidget);
    expect(find.textContaining('Avancer l\'échafaudage'), findsNothing);
  });

  final vWorksite = Worksite(
    id: 'w',
    name: 'Maison démo',
    rooms: [rectangleRoom()],
    journal: const [
      JournalEntry(
        id: 'a',
        roomId: 'salon',
        day: '2026-11-05',
        title: 'Parquet posé',
        beforePath: '/p/a0.jpg',
        photoPath: '/p/a.jpg',
      ),
    ],
  );

  testWidgets('souvenirs : avant puis après, diaporama qui avance seul', (pTester) async {
    await pTester.pumpWidget(
      localized(MemoriesScreen(worksite: vWorksite, photo: (pPath) => Text(pPath))),
    );
    expect(find.text('Avant'), findsOneWidget);
    expect(find.text('/p/a0.jpg'), findsOneWidget);
    expect(find.text('Parquet posé'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.textContaining('Du 2026-11-05 au 2026-11-05'), findsOneWidget);

    await pTester.tap(find.byTooltip('Lancer le diaporama'));
    await pTester.pump();
    await pTester.pump(const Duration(seconds: 4));
    await pTester.pump();
    expect(find.text('Après'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    await pTester.tap(find.byTooltip('Arrêter le diaporama'));
    await pTester.pump();
    expect(find.byTooltip('Lancer le diaporama'), findsOneWidget);
  });

  testWidgets('souvenirs : sans photo, le carnet explique quoi faire', (pTester) async {
    await pTester.pumpWidget(
      localized(
        const MemoriesScreen(
          worksite: Worksite(id: 'w', name: 'Vide'),
        ),
      ),
    );
    expect(find.textContaining('Ajoutez des photos d\'avant et d\'après'), findsOneWidget);
    expect(find.byTooltip('Souvenirs en PDF'), findsNothing);
  });

  test('souvenirs en PDF, photo lue et photo disparue', () async {
    final vRead = <String>[];
    final vBytes = await buildMemoriesPdf(
      AppLocalizationsFr(),
      vWorksite,
      pRead: (pPath) {
        vRead.add(pPath);
        return pPath.endsWith('a0.jpg') ? _aPixel : null;
      },
    );
    expect(vRead, ['/p/a0.jpg', '/p/a.jpg']);
    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
  });
}

/// Image PNG d'un pixel, pour une photo fictive.
final _aPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);
