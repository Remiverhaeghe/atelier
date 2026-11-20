import 'package:atelier/app.dart';
import 'package:atelier/state/worksites_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/captures/demo.dart';
import '../test/support/memory_settings.dart';
import '../test/support/memory_storage.dart';

/// Captures de la fiche Play Store, prises sur un vrai Android avec le chantier fictif :
/// `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/captures_play_test.dart`.
void main() {
  final vBinding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures de la fiche', (pTester) async {
    final vStorage = MemoryStorage()..saved = [demoWorksite()];
    final vController = WorksitesController(vStorage);
    await vController.load();
    await pTester.pumpWidget(AtelierApp(controller: vController, settings: await frenchSettings()));
    await pTester.pumpAndSettle();
    // Sur Android, la surface Flutter doit passer en image avant la première capture
    await vBinding.convertFlutterSurfaceToImage();
    await pTester.pumpAndSettle();

    Future<void> vShot(String pName) async {
      await pTester.pumpAndSettle();
      // Le temps que l'onglet finisse de glisser et que le repère de l'appui s'efface
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      await pTester.pumpAndSettle();
      await vBinding.takeScreenshot(pName);
    }

    await vShot('1-chantiers');
    await pTester.tap(find.text('Maison de démonstration'));
    await vShot('2-chantier');
    // Les pièces sont sous les tuiles d'accueil : la liste ne les construit qu'en défilant
    // Sans .first : un .first sur une liste encore vide échoue avant même de défiler
    final vRoom = find.text('Salon');
    await pTester.scrollUntilVisible(
      vRoom,
      300,
      scrollable: find
          .byWidgetPredicate(
            (pWidget) => pWidget is Scrollable && pWidget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await pTester.pumpAndSettle();
    await pTester.tap(vRoom.first);
    await vShot('3-piece');
    for (final (vTab, vName) in [
      ('Parquet', '4-parquet'),
      ('Pose', '5-pose'),
      ('Plinthes', '6-plinthes'),
      ('Peinture', '7-peinture'),
    ]) {
      await pTester.tap(find.widgetWithText(Tab, vTab));
      await vShot(vName);
    }
  });
}
