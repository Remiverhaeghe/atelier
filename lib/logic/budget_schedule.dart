/// Échéancier du budget : ce qui a été payé mois par mois, et quand le reste sera payé avec la
/// somme mise de côté chaque mois.
library;

import 'expenses.dart';

/// Montant d'un mois, au format AAAA-MM.
typedef MonthAmount = ({String month, double amount});

String monthOf(DateTime pDay) => '${pDay.year}-${pDay.month.toString().padLeft(2, '0')}';

/// Dépenses regroupées par mois, du plus ancien au plus récent.
List<MonthAmount> spentByMonth(List<Expense> pExpenses) {
  final vMonths = <String, double>{};
  for (final vExpense in pExpenses) {
    final vMonth = vExpense.date.length >= 7 ? vExpense.date.substring(0, 7) : vExpense.date;
    vMonths[vMonth] = (vMonths[vMonth] ?? 0) + vExpense.amount;
  }

  return [
    for (final vMonth in vMonths.keys.toList()..sort()) (month: vMonth, amount: vMonths[vMonth]!),
  ];
}

/// Reste à payer [pLeft] étalé sur les mois à venir à partir de [pFrom], [pMonthly] par mois,
/// le dernier mois prenant le reliquat. Vide si rien ne reste ou si rien n'est mis de côté.
List<MonthAmount> remainingSchedule(double pLeft, double pMonthly, DateTime pFrom) {
  final rMonths = <MonthAmount>[];
  if (pLeft <= 0 || pMonthly <= 0) {
    return rMonths;
  }
  var vLeft = pLeft;
  var vMonth = DateTime(pFrom.year, pFrom.month);
  // Au-delà de dix ans, l'échéancier ne sert plus à rien : on s'arrête là
  while (vLeft > 1e-9 && rMonths.length < 120) {
    final vAmount = vLeft < pMonthly ? vLeft : pMonthly;
    rMonths.add((month: monthOf(vMonth), amount: vAmount));
    vLeft -= vAmount;
    vMonth = DateTime(vMonth.year, vMonth.month + 1);
  }

  return rMonths;
}

/// Affiche AAAA-MM en MM/AAAA.
String monthLabel(String pMonth) =>
    pMonth.length == 7 ? '${pMonth.substring(5)}/${pMonth.substring(0, 4)}' : pMonth;
