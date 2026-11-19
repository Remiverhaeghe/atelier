/// Outillage prêté : à qui, depuis quand, et quand le réclamer. Outillage loué : date de
/// retour, caution, coût par jour et rappel la veille du retour.
library;

import 'reminders.dart';

class Loan {
  const Loan({
    required this.id,
    required this.tool,
    required this.person,
    required this.since,
    this.returnBy,
    this.depositEuros = 0,
    this.dayEuros = 0,
  });

  final String id;
  final String tool;

  /// À qui l'outil est prêté, ou le loueur pour un outil loué.
  final String person;

  /// Jour du prêt ou du début de la location, au format AAAA-MM-JJ.
  final String since;

  /// Jour où l'outil loué doit être rendu, au format AAAA-MM-JJ ; null pour un outil prêté.
  final String? returnBy;

  /// Caution laissée au loueur, rendue au retour de l'outil.
  final double depositEuros;

  /// Prix de location pour une journée.
  final double dayEuros;

  bool get rented => returnBy != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'tool': tool,
    'person': person,
    'since': since,
    if (returnBy != null) 'returnBy': returnBy,
    if (depositEuros != 0) 'depositEuros': depositEuros,
    if (dayEuros != 0) 'dayEuros': dayEuros,
  };

  static Loan fromJson(Map<String, Object?> pJson) => Loan(
    id: pJson['id']! as String,
    tool: (pJson['tool'] as String?) ?? '',
    person: (pJson['person'] as String?) ?? '',
    since: pJson['since']! as String,
    returnBy: pJson['returnBy'] as String?,
    depositEuros: (pJson['depositEuros'] as num?)?.toDouble() ?? 0,
    dayEuros: (pJson['dayEuros'] as num?)?.toDouble() ?? 0,
  );
}

/// Au-delà de deux semaines, un outil prêté mérite qu'on le réclame.
const loanReminderDays = 14;

DateTime _day(DateTime pDate) => DateTime(pDate.year, pDate.month, pDate.day);

int loanDays(Loan pLoan, DateTime pToday) {
  final vSince = DateTime.parse(pLoan.since);

  return _day(pToday).difference(vSince).inDays;
}

bool loanOverdue(Loan pLoan, DateTime pToday) => pLoan.rented
    ? rentalLateDays(pLoan, pToday) > 0
    : loanDays(pLoan, pToday) > loanReminderDays;

/// Prêts du plus ancien au plus récent : ceux à réclamer d'abord.
List<Loan> sortedLoans(List<Loan> pLoans) =>
    [...pLoans]..sort((pA, pB) => pA.since.compareTo(pB.since));

/// Jours facturés d'une location : du début au retour prévu, un jour au moins (pris le matin,
/// rendu le lendemain matin, c'est une journée).
int rentalDays(Loan pLoan) {
  final vReturn = pLoan.returnBy;
  if (vReturn == null) {
    return 0;
  }
  final vDays = DateTime.parse(vReturn).difference(DateTime.parse(pLoan.since)).inDays;
  final rDays = vDays < 1 ? 1 : vDays;

  return rDays;
}

/// Coût prévu de la location, caution non comprise.
double rentalCost(Loan pLoan) => rentalDays(pLoan) * pLoan.dayEuros;

/// Jours de retard après le retour prévu ; 0 tant qu'on est dans les temps.
int rentalLateDays(Loan pLoan, DateTime pToday) {
  final vReturn = pLoan.returnBy;
  if (vReturn == null) {
    return 0;
  }
  final vLate = _day(pToday).difference(DateTime.parse(vReturn)).inDays;
  final rLate = vLate < 0 ? 0 : vLate;

  return rLate;
}

/// Numéro du rappel d'une location, pour le retrouver et l'annuler au retour de l'outil.
String rentalReminderId(Loan pLoan) => 'location-${pLoan.id}';

/// Heure du rappel la veille du retour : en fin de journée, pour préparer l'outil et la caution.
const rentalReminderHour = 18;

/// Rappel la veille du retour de l'outil loué ; null pour un outil prêté.
Reminder? rentalReminder(Loan pLoan) {
  final vReturn = pLoan.returnBy;
  if (vReturn == null) {
    return null;
  }
  final vDay = DateTime.parse(vReturn).subtract(const Duration(days: 1));
  final rReminder = Reminder(
    id: rentalReminderId(pLoan),
    kind: WaitKind.custom,
    label: pLoan.tool,
    dueAt: DateTime(vDay.year, vDay.month, vDay.day, rentalReminderHour),
  );

  return rReminder;
}
