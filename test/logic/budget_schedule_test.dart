import 'package:atelier/logic/budget_schedule.dart';
import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dépenses regroupées par mois, dans l\'ordre', () {
    final vMonths = spentByMonth(const [
      Expense(id: 'a', label: 'Parquet', amount: 600, date: '2026-11-03'),
      Expense(id: 'b', label: 'Plinthes', amount: 80, date: '2026-10-20'),
      Expense(id: 'c', label: 'Colle', amount: 20.5, date: '2026-11-15'),
      Expense(id: 'd', label: 'Ancien', amount: 5, date: '2026'),
    ]);
    expect([for (final vMonth in vMonths) vMonth.month], ['2026', '2026-10', '2026-11']);
    expect(vMonths.last.amount, 620.5);
  });

  test('reste étalé mois par mois, le dernier prend le reliquat', () {
    final vSchedule = remainingSchedule(1000, 300, DateTime(2026, 11, 16));
    expect([for (final vMonth in vSchedule) vMonth.month], [
      '2026-11',
      '2026-12',
      '2027-01',
      '2027-02',
    ]);
    expect(vSchedule.last.amount, closeTo(100, 1e-9));
    expect(remainingSchedule(0, 300, DateTime(2026)), isEmpty);
    expect(remainingSchedule(500, 0, DateTime(2026)), isEmpty);
    expect(remainingSchedule(1e6, 1, DateTime(2026)), hasLength(120));
    expect(monthLabel('2027-01'), '01/2027');
    expect(monthLabel('2027'), '2027');
  });

  test('la somme mensuelle est gardée avec le chantier', () {
    final vWorksite = const Worksite(id: 'w', name: 'Maison').copyWith(monthlyBudget: 250);
    expect(Worksite.fromJson(vWorksite.toJson()).monthlyBudget, 250);
    expect(Worksite.fromJson(const Worksite(id: 'w', name: 'M').toJson()).monthlyBudget, isNull);
  });
}
