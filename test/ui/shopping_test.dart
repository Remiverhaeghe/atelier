import 'dart:convert';

import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/shopping_screen.dart';
import 'package:atelier/ui/shopping_texts.dart';
import 'package:atelier/ui/worksite_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
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

  test('la fiche PDF se construit avec la police de l\'appli, qui a le €', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final vBytes = await buildWorksitePdf(vText, vWorksite);

    expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    expect(latin1.decode(vBytes, allowInvalid: true), contains('Barlow'));
  });

  testWidgets('un prix saisi met le total à jour et s\'enregistre', (pTester) async {
    tallScreen(pTester);
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

  testWidgets('une dépense saisie avec son ticket réduit le reste du budget', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()..saved = [vWorksite];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(
        ShoppingScreen(
          controller: vController,
          worksiteId: 'maison',
          photos: (pId) async => '/tickets/$pId.jpg',
        ),
      ),
    );

    expect(find.text('Dépensé : 0,00 €'), findsOneWidget);
    await pTester.tap(find.text('Ajouter une dépense'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pump();
    expect(find.text('Indique l\'achat et un montant.'), findsOneWidget);

    // Les champs de la boîte de dialogue, pas ceux des courses derrière
    final vFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await pTester.enterText(vFields.at(0), 'Parquet chêne');
    await pTester.enterText(vFields.at(1), '200');
    await pTester.tap(find.text('Photo du ticket'));
    await pTester.pumpAndSettle();
    expect(find.text('Ticket gardé'), findsOneWidget);
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vExpense = vStorage.saved.single.expenses.single;
    expect(vExpense.amount, 200);
    expect(vExpense.receiptPath, startsWith('/tickets/'));
    expect(find.text('Reste du budget prévu : -17,00 €'), findsNothing);
    expect(find.text('Budget dépassé de 17,00 €'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.expenses, isEmpty);
  });

  testWidgets('ticket collé : achat, montant et date remplis', (pTester) async {
    tallScreen(pTester);
    pTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      pCall,
    ) async {
      if (pCall.method == 'Clipboard.getData') {
        return {'text': 'BRICO DÉMO\n14/11/2026\nCOLLE 24,90\nTOTAL TTC 24,90'};
      }
      return null;
    });
    addTearDown(
      () => pTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final vStorage = MemoryStorage()..saved = [vWorksite];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(
      localized(ShoppingScreen(controller: vController, worksiteId: 'maison')),
    );

    await pTester.tap(find.text('Ajouter une dépense'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Coller le texte du ticket'));
    await pTester.pumpAndSettle();
    expect(find.text('Ticket du 2026-11-14'), findsOneWidget);
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();

    final vExpense = vStorage.saved.single.expenses.single;
    expect((vExpense.label, vExpense.amount, vExpense.date), ('BRICO DÉMO', 24.90, '2026-11-14'));
  });
}
