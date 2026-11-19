import 'package:atelier/logic/worksite.dart';
import 'package:atelier/logic/workshop_stock.dart';
import 'package:atelier/state/workshop_controller.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/storage/workshop_store.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/project_cutting_views.dart';
import 'package:atelier/ui/wood_defect_scenes.dart';
import 'package:atelier/ui/workshop_stock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';
import '../support/rooms.dart';

Future<void> openTile(WidgetTester pTester, String pTitle) async {
  tallScreen(pTester);
  await pTester.pumpWidget(localized(const CalculatorsScreen()));
  await scrollToTile(pTester, pTitle);
  await pTester.tap(find.text(pTitle));
  await pTester.pumpAndSettle();
}

void main() {
  testWidgets('débit d\'une fenêtre bois, puis d\'une étagère et de pièces libres', (pTester) async {
    await openTile(pTester, 'Débit dans le commerce');

    expect(find.text('Bois de 58 × 70 mm : 1 × 240 cm, 1 × 200 cm'), findsOneWidget);
    expect(find.text('Bois de 15 × 15 mm : 1 × 240 cm, 1 × 200 cm'), findsOneWidget);
    expect(find.text('8 traits de scie, 2,4 cm mangés par la lame'), findsOneWidget);
    expect(find.byType(BarCutStrip), findsNWidgets(4));

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Étagère'));
    await pTester.pumpAndSettle();
    expect(find.text('Panneau de 18 mm : 1 panneau de 244 × 122 cm'), findsOneWidget);
    expect(find.text('Panneau de 3 mm : 1 panneau de 244 × 122 cm'), findsOneWidget);
    expect(find.byType(BarCutStrip), findsNothing);

    await pTester.tap(find.widgetWithText(ChoiceChip, 'Pièces libres'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Ajoutez les pièces à tailler'), findsOneWidget);

    await pTester.tap(find.byType(FloatingActionButton));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.widgetWithText(TextField, 'Longueur, dans le sens du fil'), '100');
    await pTester.enterText(find.widgetWithText(TextField, 'Largeur'), '50');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Panneau de 18 mm : 1 panneau de 122 × 61 cm'), findsOneWidget);
    expect(find.textContaining('1. Pièce : 1 × 100 × 50 cm'), findsOneWidget);

    await pTester.tap(find.byTooltip('Supprimer'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Ajoutez les pièces à tailler'), findsOneWidget);
  });

  testWidgets('défauts du bois : schéma par défaut, liste à cocher, tri d\'une planche', (
    pTester,
  ) async {
    await openTile(pTester, 'Défauts du bois');

    expect(find.byType(WoodDefectSketch), findsOneWidget);
    for (final vDefect in ['Fente', 'Gerce', 'Bois tors', 'Bois voilé', 'Bois tuilé', 'Humidité']) {
      await pTester.tap(find.widgetWithText(ChoiceChip, vDefect));
      await pTester.pumpAndSettle();
    }
    expect(find.textContaining('humidimètre à pointes'), findsOneWidget);

    for (var vIndex = 0; vIndex < 8; vIndex++) {
      final vBox = find.byType(CheckboxListTile).at(vIndex);
      await pTester.ensureVisible(vBox);
      await pTester.tap(vBox);
      await pTester.pump();
    }
    expect(find.textContaining('Tout est vérifié'), findsOneWidget);

    expect(find.text('Bonne'), findsOneWidget);
    final vBow = find.widgetWithText(TextField, 'Flèche sur 2 m (mm)');
    await pTester.ensureVisible(vBow);
    await pTester.enterText(vBow, '4');
    await pTester.pump();
    expect(find.text('À laisser au rayon'), findsOneWidget);
    expect(find.text('Bois voilé : À laisser au rayon'), findsOneWidget);

    await pTester.tap(find.text('Structure'));
    await pTester.pump();
    expect(find.text('Bonne'), findsOneWidget);
  });

  testWidgets('stock de l\'atelier : part du chantier réservée, article ajouté', (pTester) async {
    tallScreen(pTester);
    final vController = WorksitesController(
      MemoryStorage()
        ..saved = [
          Worksite(id: 'maison', name: 'Maison', rooms: [rectangleRoom(), lShapedRoom()]),
        ],
      pNewId: () => 'nouveau',
    );
    await vController.load();
    final vWorkshop = WorkshopController(
      MemoryWorkshopStore()
        ..saved = const [
          StockItem(
            id: 'colle',
            name: 'Colle mastic',
            category: StockCategory.glue,
            quantity: 3,
            minQuantity: 1,
            link: 'cartridges',
          ),
        ],
    );
    await vWorkshop.load();
    await pTester.pumpWidget(
      localized(
        WorkshopStockScreen(
          controller: vController,
          worksiteId: 'maison',
          workshop: vWorkshop,
          today: DateTime(2026, 11, 19),
        ),
      ),
    );
    await pTester.pumpAndSettle();

    expect(find.text('Colle mastic : 3 pris dans le stock, 1 à acheter'), findsOneWidget);
    expect(find.text('Colle mastic : 3 à acheter'), findsOneWidget);
    expect(find.text('Aucun outil prêté.'), findsOneWidget);

    await pTester.tap(find.text('Réserver pour ce chantier'));
    await pTester.pumpAndSettle();
    expect(vController.worksite('maison')!.stock['cartridges'], 3);
    expect(vWorkshop.items.single.quantity, 0);
    expect(find.text('Colle mastic : 0 pris dans le stock, 1 à acheter'), findsOneWidget);

    await pTester.tap(find.byType(FloatingActionButton));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.widgetWithText(TextField, 'Article'), 'Vis 4 × 40');
    await pTester.tap(find.text('Enregistrer'));
    await pTester.pumpAndSettle();
    expect(find.text('Vis et clous'), findsOneWidget);
    expect(vWorkshop.items.last.id, 'nouveau');

    await pTester.tap(find.byTooltip('J\'en ai racheté un').first);
    await pTester.pumpAndSettle();
    expect(vWorkshop.items.last.quantity, 2);
  });
}
