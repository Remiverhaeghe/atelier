import 'package:atelier/ui/height_work_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('travail en hauteur : tout cocher avant de monter', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const HeightWorkScreen()));

    expect(find.byType(CheckboxListTile), findsNWidgets(4));
    expect(find.text('Il reste des points à vérifier avant de monter.'), findsOneWidget);

    for (var vIndex = 0; vIndex < 4; vIndex++) {
      await pTester.tap(find.byType(CheckboxListTile).at(vIndex));
      await pTester.pump();
    }
    expect(find.textContaining('Tout est coché'), findsOneWidget);

    await pTester.tap(find.text("Sur un toit ou au bord d'un vide sans garde-corps"));
    await pTester.pump();
    expect(find.textContaining('Harnais accroché'), findsOneWidget);
    expect(find.text('Il reste des points à vérifier avant de monter.'), findsOneWidget);
  });

  testWidgets('échafaudage : stabilisateurs sur base étroite, pas sur base large', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const HeightWorkScreen()));
    await pTester.ensureVisible(find.text('Échafaudage roulant'));

    expect(find.text('Plancher à 200 cm : 2 éléments de 2 m'), findsOneWidget);
    expect(
      find.text('Stabilisateurs obligatoires à cette hauteur pour cette base'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Base large (135 cm)'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('Stable sans stabilisateurs'), findsOneWidget);
  });
}
