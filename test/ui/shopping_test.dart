import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/shopping_screen.dart';
import 'package:atelier/ui/shopping_texts.dart';
import 'package:atelier/ui/worksite_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_storage.dart';
import '../support/rooms.dart';

void main() {
  final AppLocalizations vText = AppLocalizationsFr();
  final vWorksite = Worksite(
    id: 'maison',
    name: 'Maison',
    rooms: [rectangleRoom()],
    prices: const {'parquetPacks': 30.5},
  );

  test('la liste de courses en texte, avec prix, total et prix manquants', () {
    final vText2 = shoppingText(vText, vWorksite);

    expect(vText2, startsWith('Liste de courses : Maison'));
    expect(vText2, contains('- Paquets de parquet : 6 × 30,50 € = 183,00 €'));
    expect(vText2, contains('- Barres de plinthe : 8 à acheter, prix à saisir'));
    expect(vText2, contains('Total : 183,00 €'));
    expect(vText2, endsWith('Des prix manquent : le total est incomplet.'));
  });

  test('prix affichés', () {
    expect(formatEuros(30.5), '30,50');
    expect(priceField(null), '');
    expect(priceField(30.5), '30,5');
  });

  test('la fiche PDF se construit', () async {
    final vBytes = await buildWorksitePdf(vText, vWorksite);

    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
  });

  testWidgets('un prix saisi met le total à jour et s\'enregistre', (pTester) async {
    final vStorage = MemoryStorage()..saved = [vWorksite];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShoppingScreen(controller: vController, worksiteId: 'maison'),
      ),
    );

    expect(find.text('Total : 183,00 €'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Prix unitaire (€)').at(2), '8');
    await pTester.pump();

    expect(vStorage.saved.single.prices['baseboardBars'], 8);
    expect(find.text('Total : 247,00 €'), findsOneWidget);
  });
}
