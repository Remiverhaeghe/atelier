import 'package:atelier/logic/wood_species.dart';
import 'package:atelier/ui/wood_species_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('bois dehors : douglas conseillé, sapin refusé sans traitement', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        const Scaffold(body: WoodSpeciesCard(useClass: UseClass.outdoor)),
      ),
    );

    expect(find.text('Convient à cet usage sans traitement'), findsOneWidget);
    expect(
      find.textContaining('Douglas, Mélèze, Chêne, Bois exotique (iroko, ipé)'),
      findsOneWidget,
    );

    await pTester.tap(find.text('Douglas').last);
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Sapin, épicéa').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Ne tient pas ici sans traitement'), findsOneWidget);
  });
}
