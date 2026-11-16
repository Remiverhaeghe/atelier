import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/shopping_line_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('article acheté : son ticket est rappelé sur la ligne', (pTester) async {
    tallScreen(pTester);
    const vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      bought: ['parquetPacks'],
      expenses: [
        Expense(
          id: 'e',
          label: 'Brico démo',
          amount: 312.4,
          date: '2026-11-12',
          receiptPath: '/photos/ticket.jpg',
          items: ['parquetPacks'],
        ),
      ],
    );
    await pTester.pumpWidget(
      localized(
        Scaffold(
          body: ShoppingLineCard(
            line: const ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 3, unitPrice: 30),
            worksite: vWorksite,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Ticket du 2026-11-12, Brico démo : 312,40 €'), findsOneWidget);
    expect(find.byTooltip('Voir le ticket'), findsOneWidget);
  });

  testWidgets('article pas encore acheté : ni ticket ni bouton', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        Scaffold(
          body: ShoppingLineCard(
            line: const ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 3, unitPrice: 30),
            worksite: const Worksite(id: 'w', name: 'Maison'),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.textContaining('Ticket du'), findsNothing);
    expect(find.byTooltip('Voir le ticket'), findsNothing);
  });
}
