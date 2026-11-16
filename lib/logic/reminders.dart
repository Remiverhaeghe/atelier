/// Rappels du chantier : quand l'attente est finie (acclimatation, séchage), sans réseau.
library;

/// Attentes courantes, en heures.
enum WaitKind {
  acclimatise(48),
  screed(48),
  filler(24),
  paintCoat(6),
  glue(24),
  custom(0);

  const WaitKind(this.hours);

  final int hours;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.kind,
    required this.label,
    required this.dueAt,
    this.roomId,
  });

  final String id;
  final WaitKind kind;
  final String label;
  final DateTime dueAt;
  final String? roomId;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'dueAt': dueAt.toIso8601String(),
    if (roomId != null) 'roomId': roomId,
  };

  static Reminder fromJson(Map<String, Object?> pJson) => Reminder(
    id: pJson['id']! as String,
    kind: WaitKind.values.asNameMap()[pJson['kind']] ?? WaitKind.custom,
    label: (pJson['label'] as String?) ?? '',
    dueAt: DateTime.parse(pJson['dueAt']! as String),
    roomId: pJson['roomId'] as String?,
  );
}

/// Rappel qui tombe après l'attente de [pKind], ou [pHours] pour une attente choisie.
Reminder startWait({
  required String pId,
  required WaitKind pKind,
  required DateTime pNow,
  String pLabel = '',
  String? pRoomId,
  int? pHours,
}) => Reminder(
  id: pId,
  kind: pKind,
  label: pLabel,
  dueAt: pNow.add(Duration(hours: pHours ?? pKind.hours)),
  roomId: pRoomId,
);

/// Rappels arrivés à échéance d'abord, puis les suivants du plus proche au plus lointain.
List<Reminder> sortedReminders(List<Reminder> pReminders) =>
    [...pReminders]..sort((pA, pB) => pA.dueAt.compareTo(pB.dueAt));

/// Heures restantes, arrondies à l'heure au-dessus ; 0 quand c'est prêt.
int hoursLeft(Reminder pReminder, DateTime pNow) {
  final vMinutes = pReminder.dueAt.difference(pNow).inMinutes;
  final rHours = vMinutes <= 0 ? 0 : (vMinutes / 60).ceil();

  return rHours;
}

/// Numéro de notification d'un rappel, stable d'un lancement à l'autre (FNV-1a sur 31 bits).
int notificationId(String pId) {
  var vHash = 0x811c9dc5;
  for (final vUnit in pId.codeUnits) {
    vHash = ((vHash ^ vUnit) * 0x01000193) & 0xffffffff;
  }

  return vHash & 0x7fffffff;
}
