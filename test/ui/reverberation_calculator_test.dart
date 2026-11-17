import 'package:atelier/ui/calculators_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('écho : panneaux tant que la pièce résonne, plus rien une fois traitée', (
    pTester,
  ) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const CalculatorsScreen()));
    await pTester.ensureVisible(find.text("Écho d'une grande pièce"));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text("Écho d'une grande pièce"));
    await pTester.pumpAndSettle();

    // Meublée, parquet, plafond en plâtre : 0,161 × 240 m³ / 29,16 m²
    expect(find.text('Réverbération : 1,3 s'), findsOneWidget);
    expect(find.textContaining('panneaux acoustiques'), findsOneWidget);

    await pTester.tap(find.text('Plâtre ou plaque peinte'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Dalles ou plaques acoustiques perforées').last);
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Parquet, stratifié'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Moquette').last);
    await pTester.pumpAndSettle();
    expect(find.textContaining('Confortable'), findsOneWidget);
  });
}
