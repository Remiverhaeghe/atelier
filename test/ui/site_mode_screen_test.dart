import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/site_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('une coupe et une rangée à la fois, lues à voix haute, écran allumé', (
    pTester,
  ) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    final vSpoken = <String>[];
    final vAwake = <bool>[];
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (pText) async => vSpoken.add(pText),
          awake: (pOn) async => vAwake.add(pOn),
        ),
      ),
    );
    await pTester.pumpAndSettle();
    expect(vAwake, [true]);
    expect(find.textContaining('Plinthe 1, mur 1'), findsOneWidget);
    expect(find.textContaining('Rangée 1 :'), findsOneWidget);

    await pTester.tap(find.text('Lire à voix haute').first);
    await pTester.pump();
    expect(vSpoken.single, startsWith('Plinthe 1, mur 1'));

    await pTester.tap(find.text('Fait').first);
    await pTester.pumpAndSettle();
    // La coupe suivante suit l'ordre des barres : un autre morceau, avec sa barre
    expect(find.textContaining('Plinthe 1, mur 1'), findsNothing);
    expect(find.textContaining('Plinthe '), findsOneWidget);
    expect(find.textContaining('Barre '), findsOneWidget);
    expect(vStorage.saved.single.rooms.single.cutPieces, [0]);

    await pTester.tap(find.text('Fait').last);
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.single.laidRows, [1]);

    await pTester.pumpWidget(const SizedBox());
    expect(vAwake, [true, false]);
  });

  testWidgets('sans plan de pose ni plinthes, le mode chantier le dit', (pTester) async {
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison démo',
          rooms: [rectangleRoom().copyWith(walls: const [])],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (_) async => throw StateError('pas de moteur'),
          awake: (_) async => throw StateError('pas de greffon'),
        ),
      ),
    );
    await pTester.pumpAndSettle();
    expect(find.text('Toutes les plinthes sont coupées.'), findsOneWidget);
    expect(find.textContaining('Pas encore de plan de pose'), findsOneWidget);
    expect(find.text('Fait'), findsNothing);
  });

  testWidgets('au micro : relire la rangée, cocher la coupe, phrase incomprise', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    final vSpoken = <String>[];
    final vPhrases = ['répète la rangée', 'coupe faite', 'bonjour'];
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (pText) async => vSpoken.add(pText),
          awake: (_) async {},
          listener: () async => vPhrases.removeAt(0),
        ),
      ),
    );
    await pTester.pumpAndSettle();

    await pTester.tap(find.byTooltip('Commande vocale'));
    await pTester.pumpAndSettle();
    expect(vSpoken.last, startsWith('Rangée 1'));

    await pTester.tap(find.byTooltip('Commande vocale'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.rooms.single.cutPieces, [0]);
    expect(vSpoken.last, 'C\'est noté.');

    await pTester.tap(find.byTooltip('Commande vocale'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Pas compris : « bonjour »'), findsOneWidget);
  });

  testWidgets('mode nuit : fond noir et textes rouges, puis retour', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'w', name: 'Maison démo', rooms: [rectangleRoom()]),
        ],
    );
    await vController.load();
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (_) async {},
          awake: (_) async {},
        ),
      ),
    );
    await pTester.pumpAndSettle();
    Color? vBackground() =>
        Theme.of(pTester.element(find.byType(Scaffold).last)).scaffoldBackgroundColor;
    expect(vBackground(), isNot(Colors.black));

    await pTester.tap(find.byTooltip('Mode nuit'));
    await pTester.pumpAndSettle();
    expect(vBackground(), Colors.black);

    await pTester.tap(find.byTooltip('Quitter le mode nuit'));
    await pTester.pumpAndSettle();
    expect(vBackground(), isNot(Colors.black));
  });

  testWidgets('les murs déduits sur le dessin sont rappelés à mesurer', (pTester) async {
    tallScreen(pTester);
    final vRoom = rectangleRoom();
    final vStorage = MemoryStorage()
      ..saved = [
        Worksite(
          id: 'w',
          name: 'Maison démo',
          rooms: [
            vRoom.copyWith(
              walls: [
                for (final (vIndex, vWall) in vRoom.walls.indexed)
                  vWall.copyWith(deduced: vIndex >= 2),
              ],
            ),
          ],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        SiteModeScreen(
          controller: vController,
          worksiteId: 'w',
          roomId: 'salon',
          speaker: (pText) async {},
          awake: (pOn) async {},
        ),
      ),
    );
    await pTester.pumpAndSettle();

    expect(find.textContaining('Murs à mesurer sur place : 3, 4.'), findsOneWidget);
    await pTester.pumpWidget(const SizedBox());
  });
}
