/// Dépenses réelles du chantier, à comparer au budget prévu.
library;

/// Un achat fait : ce qui a été payé, quand, et le ticket en photo si on l'a gardé.
class Expense {
  const Expense({
    required this.id,
    required this.label,
    required this.amount,
    required this.date,
    this.receiptPath,
  });

  final String id;
  final String label;

  /// Montant payé, en euros.
  final double amount;

  /// Jour de l'achat, au format AAAA-MM-JJ.
  final String date;
  final String? receiptPath;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'date': date,
    if (receiptPath != null) 'receiptPath': receiptPath,
  };

  static Expense fromJson(Map<String, Object?> pJson) => Expense(
    id: pJson['id']! as String,
    label: pJson['label']! as String,
    amount: (pJson['amount']! as num).toDouble(),
    date: pJson['date']! as String,
    receiptPath: pJson['receiptPath'] as String?,
  );
}

/// Total payé.
double spentTotal(List<Expense> pExpenses) =>
    pExpenses.fold(0, (pSum, pExpense) => pSum + pExpense.amount);

/// Reste du budget prévu ; négatif en cas de dépassement.
double budgetLeft(double pPlanned, List<Expense> pExpenses) => pPlanned - spentTotal(pExpenses);

/// Dépenses de la plus récente à la plus ancienne.
List<Expense> byDate(List<Expense> pExpenses) =>
    [...pExpenses]..sort((pA, pB) => pB.date.compareTo(pA.date));
