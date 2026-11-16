import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/delivery_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('livraison : manque noté puis tout reçu', (pTester) async {
    tallScreen(pTester);
    var vWorksite = const Worksite(id: 'w', name: 'Maison');
    const vLines = [ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 12, unitPrice: 30)];
    Future<void> vShow() => pTester.pumpWidget(
      localized(
        Scaffold(
          body: ListView(
            children: [
              DeliveryCard(
                worksite: vWorksite,
                lines: vLines,
                onChanged: (pWorksite) => vWorksite = pWorksite,
              ),
            ],
          ),
        ),
      ),
    );

    await vShow();
    await pTester.tap(find.text('Vérifier une livraison'));
    await pTester.pumpAndSettle();
    await pTester.enterText(find.byType(TextField), '10');
    await pTester.pump();
    expect(vWorksite.received, {'parquetPacks': 10});
    await vShow();
    expect(find.textContaining('il en manque 2'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), '12');
    await pTester.pump();
    await vShow();
    expect(find.text('Tout est arrivé'), findsOneWidget);
  });

  testWidgets('rien de commandé : pas de carte', (pTester) async {
    await pTester.pumpWidget(
      localized(
        DeliveryCard(
          worksite: const Worksite(id: 'w', name: 'Maison'),
          lines: const [],
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Vérifier une livraison'), findsNothing);
  });
}
