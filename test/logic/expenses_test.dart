import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vExpenses = [
    Expense(id: 'a', label: 'Parquet', amount: 320.5, date: '2026-11-10'),
    Expense(id: 'b', label: 'Plinthes', amount: 48, date: '2026-11-14', receiptPath: '/t.jpg'),
  ];

  test('total payé, reste du budget, dépassement', () {
    expect(spentTotal(vExpenses), 368.5);
    expect(budgetLeft(400, vExpenses), closeTo(31.5, 1e-9));
    expect(budgetLeft(300, vExpenses), closeTo(-68.5, 1e-9));
    expect(spentTotal(const []), 0);
  });

  test('les plus récentes d\'abord, et relues depuis le JSON', () {
    expect(byDate(vExpenses).map((pExpense) => pExpense.id), ['b', 'a']);

    final vBack = Worksite.fromJson(
      const Worksite(id: 'w', name: 'M', expenses: vExpenses).toJson(),
    );
    expect(vBack.expenses.map((pExpense) => pExpense.toJson()), vExpenses.map((pE) => pE.toJson()));
  });

  test('ticket d\'un article : le plus récent qui le couvre, gardé avec la dépense', () {
    const vTickets = [
      Expense(id: 'a', label: 'Brico', amount: 300, date: '2026-11-10', items: ['parquetPacks']),
      Expense(
        id: 'b',
        label: 'Brico',
        amount: 40,
        date: '2026-11-12',
        items: ['parquetPacks', 'glueBuckets'],
      ),
      Expense(id: 'c', label: 'Quincaillerie', amount: 8, date: '2026-11-13'),
    ];
    expect(expenseFor(vTickets, 'parquetPacks')!.id, 'b');
    expect(expenseFor(vTickets, 'nailBoxes'), isNull);
    expect(Expense.fromJson(vTickets[1].toJson()).items, ['parquetPacks', 'glueBuckets']);
    expect(vTickets[2].toJson().containsKey('items'), isFalse);
  });
}
