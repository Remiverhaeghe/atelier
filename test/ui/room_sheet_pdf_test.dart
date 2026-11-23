import 'dart:convert';
import 'dart:typed_data';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/slope.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/room_sheet_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('fiche de la pièce : plan, murs déduits, ouvertures, rampants et reprises', () async {
    final vRoom = rectangleRoom();
    final vFull = vRoom.copyWith(
      walls: [
        vRoom.walls[0].copyWith(
          openings: const [Opening(kind: OpeningKind.door, offsetMm: 300, widthMm: 830)],
        ),
        vRoom.walls[1].copyWith(
          openings: const [Opening(kind: OpeningKind.window, offsetMm: 900, widthMm: 1200)],
        ),
        vRoom.walls[2].copyWith(deduced: true),
        vRoom.walls[3],
      ],
      slope: const Slope(wallIndex: 0, lowMm: 900, runMm: 1500),
      slope2: const Slope(wallIndex: 2, lowMm: 1000, runMm: 1200),
      fixtures: const [
        Fixture(
          id: 'm',
          kind: FixtureKind.mezzanine,
          xMm: 2000,
          yMm: 1500,
          widthMm: 2000,
          depthMm: 1500,
          notchWidthMm: 800,
          notchDepthMm: 900,
          notchCorner: 2,
        ),
      ],
      touchUps: const [
        TouchUp(id: 't1', label: 'Fissure au plafond', note: 'Enduit fin', toBuy: 'Bande'),
        TouchUp(id: 't2', label: 'Trou de cheville', markerXMm: 1000, markerYMm: 500),
        TouchUp(id: 't3', label: 'Plinthe décollée', passes: 2, donePasses: 2),
        TouchUp(
          id: 't4',
          label: 'Éclat au coin',
          photoPath: 'photo-fictive.png',
          photoMarks: [(x: 0.5, y: 0.5), (x: 0.1, y: 0.9)],
        ),
        TouchUp(id: 't5', label: 'Photo perdue', photoPath: 'absente.png'),
        TouchUp(id: 't6', label: 'Photo abîmée', photoPath: 'abimee.png'),
      ],
    );

    // Photos lues dans une table : une image, une photo absente, des octets illisibles
    final vPhotos = {
      'photo-fictive.png': base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAIAAAA7ljmRAAAAEElEQVR4nGM40+ECRww4OQB7hhMhrFvIYAAAAABJRU5ErkJggg=='),
      'abimee.png': Uint8List.fromList([1, 2, 3]),
    };
    final vRead = <String>[];
    Uint8List? vPhoto(String pPath) {
      vRead.add(pPath);

      return vPhotos[pPath];
    }

    for (final vSheet in [vFull, const Room(id: 'v', name: 'Pièce vide')]) {
      final vBytes = await buildRoomSheetPdf(AppLocalizationsFr(), vSheet, pPhotos: vPhoto);
      expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    }
    expect(vRead, ['photo-fictive.png', 'absente.png', 'abimee.png']);
  });
}
