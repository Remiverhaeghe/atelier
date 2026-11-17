/// Outillage prêté : à qui, depuis quand, et quand le réclamer.
library;

class Loan {
  const Loan({required this.id, required this.tool, required this.person, required this.since});

  final String id;
  final String tool;
  final String person;

  /// Jour du prêt, au format AAAA-MM-JJ.
  final String since;

  Map<String, Object?> toJson() => {'id': id, 'tool': tool, 'person': person, 'since': since};

  static Loan fromJson(Map<String, Object?> pJson) => Loan(
    id: pJson['id']! as String,
    tool: (pJson['tool'] as String?) ?? '',
    person: (pJson['person'] as String?) ?? '',
    since: pJson['since']! as String,
  );
}

/// Au-delà de deux semaines, un outil prêté mérite qu'on le réclame.
const loanReminderDays = 14;

int loanDays(Loan pLoan, DateTime pToday) {
  final vSince = DateTime.parse(pLoan.since);

  return DateTime(pToday.year, pToday.month, pToday.day).difference(vSince).inDays;
}

bool loanOverdue(Loan pLoan, DateTime pToday) => loanDays(pLoan, pToday) > loanReminderDays;

/// Prêts du plus ancien au plus récent : ceux à réclamer d'abord.
List<Loan> sortedLoans(List<Loan> pLoans) =>
    [...pLoans]..sort((pA, pB) => pA.since.compareTo(pB.since));
