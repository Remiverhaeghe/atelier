import 'dart:convert';
import 'dart:typed_data';

import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/fixtures.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/trades.dart';
import 'package:atelier/ui/pro_brief_dialog.dart';
import 'package:atelier/ui/pro_brief_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('fiche artisan : un PDF avec mesures, contenu, contraintes et photos lisibles', () async {
    final vRoom = rectangleRoom().copyWith(
      fixtures: const [
        Fixture(id: 'a', kind: FixtureKind.socket, xMm: 100, yMm: 100),
        Fixture(id: 'b', kind: FixtureKind.socket, xMm: 900, yMm: 100),
        Fixture(id: 'c', kind: FixtureKind.lightSwitch, xMm: 100, yMm: 900),
      ],
    );
    final vPhotos = {
      'ok.png': base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAIAAAA7ljmRAAAAEElEQVR4nGM40+ECRww4OQB7hhMhrFvIYAAAAABJRU5ErkJggg==',
      ),
      'abimee.png': Uint8List.fromList([1, 2, 3]),
    };
    final vRead = <String>[];
    Uint8List? vReadPhoto(String pPath) {
      vRead.add(pPath);

      return vPhotos[pPath];
    }

    final vBytes = await buildProBriefPdf(
      AppLocalizationsFr(),
      vRoom,
      pTrade: 'Électricité',
      pConstraints: 'Coupure du courant le matin seulement.',
      pJournal: const [
        JournalEntry(
          id: 'j',
          roomId: 'salon',
          day: '2026-11-01',
          title: 'Tableau',
          photoPath: 'ok.png',
          beforePath: 'abimee.png',
        ),
      ],
      pPhotos: vReadPhoto,
    );

    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(vRead, ['abimee.png', 'ok.png']);
    // Sans contrainte ni photo ni contenu, la fiche se fait quand même
    final vEmpty = await buildProBriefPdf(AppLocalizationsFr(), rectangleRoom(), pTrade: 'Plomberie');
    expect(String.fromCharCodes(vEmpty.take(5)), '%PDF-');
  });

  test('les travaux à confier vont du plus délicat au plus abordable, sans les faciles', () {
    final vTrades = tradesToHandOver();

    expect(vTrades, isNotEmpty);
    expect(vTrades.any((pTrade) => pTrade.level == TradeLevel.easy), isFalse);
    expect(vTrades.first.level, TradeLevel.pro);
  });
}
