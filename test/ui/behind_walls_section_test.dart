import 'dart:convert';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/hidden_networks.dart';
import 'package:atelier/logic/house_book.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/behind_walls_section.dart';
import 'package:atelier/ui/house_book_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

final _aPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

const _aRun = HiddenRun(
  id: 'r',
  kind: NetworkKind.water,
  wallIndex: 1,
  fromAlongMm: 500,
  fromHeightMm: 200,
  toAlongMm: 500,
  toHeightMm: 1200,
);

void main() {
  testWidgets('solives repérées puis photo du mur avant fermeture', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom().copyWith(networks: [_aRun]);
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          SingleChildScrollView(
            child: BehindWallsSection(
              room: vRoom,
              onChanged: (pNew) => pSetState(() => vRoom = pNew),
              photos: (pId) async => '/photos/$pId.jpg',
              now: () => DateTime(2026, 11, 2, 10),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Mur 2 : réseaux relevés, à photographier avant de fermer'), findsOneWidget);

    await pTester.tap(find.text('Repérer des solives'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Longueur invalide.'), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Axe de la première solive depuis le début du mur'),
      '20',
    );
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.joists.single.spacingMm, 600);
    expect(find.text('Solives du plafond le long du mur 1, entraxe 60 cm'), findsOneWidget);
    expect(find.textContaining('axes à 20, 80, 140, 200, 260, 320, 380 cm'), findsOneWidget);

    await pTester.tap(find.text('Photo avant fermeture'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byType(DropdownButtonFormField<int>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Mur 2').last);
    await pTester.pumpAndSettle();
    await pTester.enterText(
      find.widgetWithText(TextField, "Note (ce qu'on voit, une cote)"),
      'PER',
    );
    await pTester.tap(find.text('Prendre la photo'));
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.photos.single.wallIndex, 1);
    expect(find.text('Mur 2, 2026-11-02'), findsOneWidget);
    expect(find.text('PER'), findsOneWidget);
    expect(find.textContaining('à photographier avant de fermer'), findsNothing);

    // Suppression de la photo puis des solives
    await pTester.tap(find.byTooltip('Supprimer').last);
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.photos, isEmpty);
    await pTester.tap(find.byTooltip('Supprimer').last);
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.joists, isEmpty);
  });

  testWidgets('photo annulée : rien n’est ajouté', (pTester) async {
    var vRoom = const Room(id: 'r', name: 'Combles');
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          BehindWallsSection(
            room: vRoom,
            onChanged: (pNew) => pSetState(() => vRoom = pNew),
            photos: (_) async => null,
          ),
        ),
      ),
    );
    await pTester.tap(find.text('Photo avant fermeture'));
    await pTester.pumpAndSettle();
    expect(find.text('Plafond'), findsOneWidget);
    await pTester.tap(find.text('Prendre la photo'));
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.isEmpty, isTrue);
    await pTester.tap(find.text('Photo avant fermeture'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Annuler'));
    await pTester.pumpAndSettle();
    expect(vRoom.behindWalls.isEmpty, isTrue);
  });

  test('le dossier de la maison se construit en PDF', () async {
    final vText = AppLocalizationsFr();
    final vRoom = rectangleRoom().copyWith(
      walls: const [
        Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        Wall(lengthMm: 3000),
        Wall(lengthMm: 4000),
        Wall(lengthMm: 3000),
      ],
      networks: [_aRun],
      behindWalls: const BehindWalls(
        joists: [
          JoistSet(id: 's', place: JoistPlace.floor, wallIndex: 0, firstMm: 300, spacingMm: 400),
        ],
        photos: [
          ClosingPhoto(id: 'p', wallIndex: 1, path: '/photos/mur.png', day: '2026-11-02'),
          ClosingPhoto(
            id: 'q',
            wallIndex: ceilingPhotoIndex,
            path: '/photos/disparue.png',
            day: '2026-11-03',
            note: 'Gaine VMC',
          ),
        ],
      ),
    );
    final vRead = <String>[];
    final vBytes = await buildHouseBookPdf(
      vText,
      Worksite(
        id: 'w',
        name: 'Maison fictive',
        rooms: [vRoom],
        journal: const [
          JournalEntry(
            id: 'j',
            roomId: 'salon',
            day: '2026-10-01',
            title: 'Fenêtre',
            product: 'PVC double vitrage',
            reference: 'FEN-001',
          ),
        ],
      ),
      pRead: (pPath) {
        vRead.add(pPath);
        return pPath.contains('disparue') ? null : _aPixel;
      },
    );
    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(vRead, ['/photos/mur.png', '/photos/disparue.png']);

    final vEmpty = await buildHouseBookPdf(vText, const Worksite(id: 'v', name: 'Vide'));
    expect(String.fromCharCodes(vEmpty.take(5)), '%PDF-');
    final vBroken = await buildHouseBookPdf(
      vText,
      Worksite(id: 'w', name: 'M', rooms: [vRoom]),
      pRead: (_) => utf8.encode('pas une image'),
    );
    expect(String.fromCharCodes(vBroken.take(5)), '%PDF-');
  });
}
