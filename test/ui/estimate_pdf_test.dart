import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/estimate_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('devis estimatif : un PDF, y compris sans aucune pièce', () async {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison démo',
      rooms: [rectangleRoom(), lShapedRoom()],
      prices: const {'parquetPacks': 30.5},
    );

    final vBytes = await buildEstimatePdf(
      AppLocalizationsFr(),
      vWorksite,
      pToday: DateTime(2026, 11, 23),
    );
    final vEmpty = await buildEstimatePdf(
      AppLocalizationsFr(),
      const Worksite(id: 'v', name: 'Vide'),
      pToday: DateTime(2026, 11, 23),
    );

    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(vEmpty.take(5)), '%PDF-');
    expect(vBytes.length, greaterThan(vEmpty.length));
  });
}
