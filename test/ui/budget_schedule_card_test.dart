import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:atelier/ui/budget_schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('échéancier : mois payés, somme mensuelle puis date de fin', (pTester) async {
    tallScreen(pTester);
    var vWorksite = const Worksite(
      id: 'w',
      name: 'Maison',
      expenses: [
        Expense(id: 'a', label: 'Parquet', amount: 600, date: '2026-10-03'),
        Expense(id: 'b', label: 'Colle', amount: 40, date: '2026-11-02'),
      ],
    );
    Future<void> vShow(double pPlanned) => pTester.pumpWidget(
      localized(
        Scaffold(
          body: ListView(
            children: [
              BudgetScheduleCard(
                worksite: vWorksite,
                planned: pPlanned,
                onChanged: (pWorksite) => vWorksite = pWorksite,
                now: DateTime(2026, 11, 16),
              ),
            ],
          ),
        ),
      ),
    );

    await vShow(1640);
    expect(find.text('10/2026 : 600,00 € payés'), findsOneWidget);
    expect(find.textContaining('Indiquez ce que vous mettez'), findsOneWidget);

    await pTester.enterText(find.byType(TextField), '400');
    await pTester.pump();
    expect(vWorksite.monthlyBudget, 400);
    await vShow(1640);
    expect(find.text('Tout payé en 01/2027'), findsOneWidget);
    expect(find.text('01/2027 : 200,00 €'), findsOneWidget);

    await vShow(500);
    expect(find.text('Tout le budget prévu est payé'), findsOneWidget);
  });
}
