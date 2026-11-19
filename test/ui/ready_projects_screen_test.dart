import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/ready_projects.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/gestures_screen.dart';
import 'package:atelier/ui/ready_projects_screen.dart';
import 'package:atelier/ui/shopping_target.dart';
import 'package:atelier/ui/workshop_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('les quatre projets sont proposés', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const ReadyProjectsScreen()));
    for (final vName in [
      'Étagère murale',
      'Châssis fixe à la place d\'un plexi',
      'Mezzanine simple',
      'Embrasure de fenêtre de toit',
    ]) {
      expect(find.text(vName), findsOneWidget);
    }
    await pTester.tap(find.text('Mezzanine simple'));
    await pTester.pumpAndSettle();
    await scrollToFirst(pTester, find.textContaining('7 × solive'));
    expect(find.textContaining('7 × solive'), findsOneWidget);
    expect(find.textContaining('garde-corps est obligatoire'), findsOneWidget);
  });

  testWidgets('étagère : débit, courses, geste lié et mode atelier', (pTester) async {
    tallScreen(pTester);
    List<ExtraItem>? vAdded;
    await pTester.pumpWidget(
      localized(
        ShoppingTarget(
          worksites: [Worksite(id: 'w', name: 'Maison démo')],
          add: (_, pItems) async => vAdded = pItems,
          child: const ReadyProjectScreen(project: ReadyProject.wallShelf),
        ),
      ),
    );
    expect(find.text('1 × planche d\'étagère : 80 cm, section 250 × 22 mm'), findsOneWidget);
    expect(find.text('3 × vis 6 × 80 pour le mur'), findsOneWidget);
    expect(find.byType(ReadyProjectSketch), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Largeur (cm)'), '120');
    await pTester.pump();
    expect(find.text('1 × planche d\'étagère : 120 cm, section 250 × 22 mm'), findsOneWidget);
    expect(find.text('4 × vis 6 × 80 pour le mur'), findsOneWidget);

    await scrollToFirst(pTester, find.text('Ajouter aux courses'));
    await pTester.tap(find.text('Ajouter aux courses'));
    await pTester.pumpAndSettle();
    expect(vAdded, isNotNull);
    expect(vAdded!.first.name, 'vis 6 × 80 pour le mur');

    await scrollToFirst(pTester, find.byTooltip('Voir le geste'));
    await pTester.tap(find.byTooltip('Voir le geste').first);
    await pTester.pumpAndSettle();
    expect(find.byType(GestureScreen), findsOneWidget);
    Navigator.of(pTester.element(find.byType(GestureScreen))).pop();
    await pTester.pumpAndSettle();

    await scrollToFirst(pTester, find.text('Suivre en mode atelier'));
    await pTester.tap(find.text('Suivre en mode atelier'));
    await pTester.pump();
    await pTester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WorkshopModeScreen), findsOneWidget);
    expect(find.text('Étape 1 sur 7'), findsOneWidget);
  });

  testWidgets('cotes hors limites : le projet le dit', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(const ReadyProjectScreen(project: ReadyProject.fixedFrame)),
    );
    expect(find.textContaining('Vitrage à commander : 50,2 × 80,2 cm'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur (cm)'), '5');
    await pTester.pump();
    expect(find.text('Ces cotes sortent des limites de ce projet.'), findsOneWidget);
  });
}
