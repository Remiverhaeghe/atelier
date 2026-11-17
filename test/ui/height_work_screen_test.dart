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
}
