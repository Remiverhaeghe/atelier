import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/units.dart';
import 'package:atelier/ui/cut_list_pdf.dart';
import 'package:atelier/ui/room_measure_picker.dart';
import 'package:atelier/ui/room_sheet_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vText = AppLocalizationsFr();

  test('une longueur s\'écrit dans l\'unité choisie, avec son nom', () {
    expect(lengthText(vText, 2450, FieldUnit.cm), '245 cm');
    expect(lengthText(vText, 2450, FieldUnit.m), '2,45 m');
    expect(lengthText(vText, 2450, FieldUnit.mm), '2450 mm');
  });

  test('les textes des PDF ne portent plus d\'unité en dur', () {
    expect(vText.roomSheetHeight('2,5 m'), 'Hauteur sous plafond : 2,5 m');
    expect(vText.sketchOpening('Porte', '90 cm', '30 cm', 'A'), 'Porte de 90 cm, à 30 cm du coin A');
    expect(
      vText.roomSheetSlope(2, '1 m', '2 m'),
      'Rampant le long du mur 2 : jambette de 1 m, pente sur 2 m au sol',
    );
  });

  test('fiche de pièce et liste de coupes se construisent dans chaque unité', () async {
    for (final vUnit in [FieldUnit.mm, FieldUnit.cm, FieldUnit.m]) {
      final vSheet = await buildRoomSheetPdf(vText, rectangleRoom(), pUnit: vUnit);
      final vCuts = await buildCutListPdf(vText, rectangleRoom(), pUnit: vUnit);

      expect(String.fromCharCodes(vSheet.take(5)), '%PDF-');
      expect(String.fromCharCodes(vCuts.take(5)), '%PDF-');
    }
  });
}
