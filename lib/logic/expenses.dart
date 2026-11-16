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
    this.items = const [],
  });

  final String id;
  final String label;

  /// Montant payé, en euros.
  final double amount;

  /// Jour de l'achat, au format AAAA-MM-JJ.
  final String date;
  final String? receiptPath;

  /// Lignes de courses payées par ce ticket (noms des articles), pour retrouver la preuve d'achat.
  final List<String> items;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'amount': amount,
    'date': date,
    if (receiptPath != null) 'receiptPath': receiptPath,
    if (items.isNotEmpty) 'items': items,
  };

  static Expense fromJson(Map<String, Object?> pJson) => Expense(
    id: pJson['id']! as String,
    label: pJson['label']! as String,
    amount: (pJson['amount']! as num).toDouble(),
    date: pJson['date']! as String,
    receiptPath: pJson['receiptPath'] as String?,
    items: [for (final vItem in (pJson['items'] as List<Object?>?) ?? const []) vItem! as String],
  );
}

/// Dernier ticket qui couvre l'article [pItem], pour une garantie ou un retour en magasin.
Expense? expenseFor(List<Expense> pExpenses, String pItem) {
  final vFound = pExpenses.where((pExpense) => pExpense.items.contains(pItem)).toList()
    ..sort((pA, pB) => pA.date.compareTo(pB.date));

  return vFound.lastOrNull;
}

/// Total payé.
double spentTotal(List<Expense> pExpenses) =>
    pExpenses.fold(0, (pSum, pExpense) => pSum + pExpense.amount);

/// Reste du budget prévu ; négatif en cas de dépassement.
double budgetLeft(double pPlanned, List<Expense> pExpenses) => pPlanned - spentTotal(pExpenses);

/// Dépenses de la plus récente à la plus ancienne.
List<Expense> byDate(List<Expense> pExpenses) =>
    [...pExpenses]..sort((pA, pB) => pB.date.compareTo(pA.date));
