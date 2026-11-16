/// Garanties des achats et des travaux : jusqu'à quand, et rappel avant la fin.
library;

/// Durées courantes, en mois.
enum WarrantyKind {
  /// Garantie légale de conformité d'un produit acheté neuf.
  conformity(24),

  /// Garantie de parfait achèvement des travaux d'un artisan.
  completion(12),

  /// Garantie biennale des équipements posés (volets, chaudière, robinetterie).
  biennial(24),

  /// Garantie décennale de l'ouvrage.
  decennial(120),
  custom(0);

  const WarrantyKind(this.months);

  final int months;
}

class Warranty {
  const Warranty({
    required this.id,
    required this.label,
    required this.kind,
    required this.start,
    this.months = 0,
  });

  final String id;
  final String label;
  final WarrantyKind kind;

  /// Jour d'achat ou de réception des travaux, au format AAAA-MM-JJ.
  final String start;

  /// Durée choisie à la main, pour [WarrantyKind.custom].
  final int months;

  int get duration => kind == WarrantyKind.custom ? months : kind.months;

  DateTime get end {
    final vStart = DateTime.parse(start);

    return DateTime(vStart.year, vStart.month + duration, vStart.day);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'kind': kind.name,
    'start': start,
    if (months > 0) 'months': months,
  };

  static Warranty fromJson(Map<String, Object?> pJson) => Warranty(
    id: pJson['id']! as String,
    label: (pJson['label'] as String?) ?? '',
    kind: WarrantyKind.values.asNameMap()[pJson['kind']] ?? WarrantyKind.custom,
    start: pJson['start']! as String,
    months: (pJson['months'] as int?) ?? 0,
  );
}

/// Prévenir deux mois avant la fin : le temps de faire constater un défaut.
const warrantyNoticeDays = 60;

enum WarrantyState { running, endingSoon, ended }

WarrantyState warrantyState(Warranty pWarranty, DateTime pToday) {
  final vLeft = pWarranty.end.difference(DateTime(pToday.year, pToday.month, pToday.day)).inDays;
  final rState = vLeft < 0
      ? WarrantyState.ended
      : (vLeft <= warrantyNoticeDays ? WarrantyState.endingSoon : WarrantyState.running);

  return rState;
}

/// Garanties qui finissent bientôt d'abord, puis par date de fin.
List<Warranty> sortedWarranties(List<Warranty> pWarranties) =>
    [...pWarranties]..sort((pA, pB) => pA.end.compareTo(pB.end));
