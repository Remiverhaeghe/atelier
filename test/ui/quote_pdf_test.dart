import 'dart:convert';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/quote_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('dossier de devis : pièces mesurées, travaux et photo illisible écartée', () async {
    final vRead = <String>[];
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison démo',
      rooms: [
        rectangleRoom().copyWith(
          touchUps: const [
            TouchUp(
              id: 't',
              label: 'Reprendre le tableau',
              note: 'Ajouter un différentiel',
              photoPath: '/p.jpg',
            ),
          ],
        ),
        const Room(id: 'v', name: 'Sans murs'),
      ],
    );
    final vBytes = await buildQuotePdf(
      AppLocalizationsFr(),
      vWorksite,
      pToday: DateTime(2026, 11, 17),
      pRead: (pPath) {
        vRead.add(pPath);
        return utf8.encode('pas une image');
      },
    );
    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(vRead, ['/p.jpg']);
  });
}
