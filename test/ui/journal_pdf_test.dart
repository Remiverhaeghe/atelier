import 'dart:convert';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/journal_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Image PNG d'un pixel, pour une photo fictive.
final _aPixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

void main() {
  test('le carnet se construit en PDF, photos lues et photos disparues', () async {
    final vText = AppLocalizationsFr();
    final vRead = <String>[];
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison démo',
      rooms: [rectangleRoom()],
      journal: const [
        JournalEntry(
          id: 'j1',
          roomId: 'salon',
          day: '2026-10-02',
          title: 'Peinture des murs',
          product: 'Acrylique mat',
          reference: 'TEINTE-0412',
          note: 'Deux couches',
          cost: 120,
          beforePath: '/photos/avant.png',
          photoPath: '/photos/apres.png',
          invoicePath: '/photos/disparue.png',
        ),
        JournalEntry(id: 'j2', roomId: 'salon', day: '2026-10-05', title: 'Joints'),
      ],
    );

    final vBytes = await buildJournalPdf(
      vText,
      vWorksite,
      pRead: (pPath) {
        vRead.add(pPath);
        return pPath.contains('disparue') ? null : _aPixel;
      },
    );
    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(vRead, containsAll(['/photos/avant.png', '/photos/apres.png', '/photos/disparue.png']));

    final vEmpty = await buildJournalPdf(vText, const Worksite(id: 'v', name: 'Vide'));
    expect(String.fromCharCodes(vEmpty.take(5)), '%PDF-');
  });

  test('une image illisible est laissée de côté', () async {
    final vBytes = await buildJournalPdf(
      AppLocalizationsFr(),
      Worksite(
        id: 'w',
        name: 'Maison',
        rooms: [rectangleRoom()],
        journal: const [
          JournalEntry(
            id: 'j',
            roomId: 'salon',
            day: '2026-10-02',
            title: 'Plinthes',
            photoPath: '/photos/abimee.jpg',
          ),
        ],
      ),
      pRead: (_) => utf8.encode('pas une image'),
    );
    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
  });
}
