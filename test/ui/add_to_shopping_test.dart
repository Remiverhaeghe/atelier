import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:atelier/ui/calculators_screen.dart';
import 'package:atelier/ui/shopping_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/memory_storage.dart';

void main() {
  testWidgets('un calcul envoie son matériel dans les courses du chantier choisi', (pTester) async {
    tallScreen(pTester);
    final vAdded = <(String, List<ExtraItem>)>[];
    await pTester.pumpWidget(
      localized(
        CalculatorsScreen(
          worksites: const [
            Worksite(id: 'a', name: 'Maison démo'),
            Worksite(id: 'b', name: 'Garage démo'),
          ],
          onAddToShopping: (pId, pItems) async => vAdded.add((pId, pItems)),
        ),
      ),
    );
    await scrollToTile(pTester, 'Tablette murale sur équerres');
    await pTester.tap(find.text('Tablette murale sur équerres'));
    await pTester.pumpAndSettle();

    await pTester.tap(find.text('Ajouter aux courses'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Garage démo'));
    await pTester.pumpAndSettle();

    expect(vAdded.single.$1, 'b');
    expect(vAdded.single.$2.first.name, 'Équerres, bras de 20 cm');
    expect(vAdded.single.$2.first.quantity, 2);
    expect(find.textContaining('aux courses de Garage démo'), findsOneWidget);
  });

  testWidgets('sans chantier : pas de bouton', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await scrollToTile(pTester, 'Tablette murale sur équerres');
    await pTester.tap(find.text('Tablette murale sur équerres'));
    await pTester.pumpAndSettle();

    expect(find.text('Ajouter aux courses'), findsNothing);
  });

  testWidgets('les courses montrent le matériel ajouté et le retirent', (pTester) async {
    tallScreen(pTester);
    final vStorage = MemoryStorage()
      ..saved = const [
        Worksite(
          id: 'w',
          name: 'Maison démo',
          extras: [ExtraItem(name: 'Sabots de solive', quantity: 18)],
        ),
      ];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(localized(ShoppingScreen(controller: vController, worksiteId: 'w')));

    expect(find.text('Sabots de solive'), findsOneWidget);
    expect(find.text('× 18'), findsOneWidget);

    await pTester.tap(find.byTooltip('Retirer de la liste'));
    await pTester.pumpAndSettle();
    expect(vStorage.saved.single.extras, isEmpty);
  });
}
