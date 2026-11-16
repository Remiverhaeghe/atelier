/// Temps passé par pièce et par étape, et estimation des pièces suivantes.
library;

import 'geometry.dart';
import 'paint.dart';
import 'planning.dart';
import 'room.dart';
import 'touch_up.dart';

/// Temps passé sur une étape d'une pièce, un jour donné.
class TimeEntry {
  const TimeEntry({
    required this.roomId,
    required this.phase,
    required this.minutes,
    required this.day,
  });

  final String roomId;
  final WorkPhase phase;
  final int minutes;

  /// Jour du travail, au format AAAA-MM-JJ.
  final String day;

  Map<String, Object?> toJson() => {
    'roomId': roomId,
    'phase': phase.name,
    'minutes': minutes,
    'day': day,
  };

  static TimeEntry fromJson(Map<String, Object?> pJson) => TimeEntry(
    roomId: pJson['roomId']! as String,
    phase: WorkPhase.values.byName(pJson['phase']! as String),
    minutes: pJson['minutes']! as int,
    day: pJson['day']! as String,
  );
}

/// Chrono lancé sur une étape d'une pièce.
class RunningTimer {
  const RunningTimer({required this.roomId, required this.phase, required this.startedAt});

  final String roomId;
  final WorkPhase phase;
  final DateTime startedAt;

  /// Minutes écoulées, une au moins, arrondies à la minute la plus proche.
  int elapsedMinutes(DateTime pNow) =>
      (pNow.difference(startedAt).inSeconds / 60).round().clamp(1, 24 * 60);

  /// Chrono arrêté : le temps rejoint ceux de la pièce, au jour du départ.
  TimeEntry stop(DateTime pNow) =>
      TimeEntry(roomId: roomId, phase: phase, minutes: elapsedMinutes(pNow), day: dayOf(startedAt));

  Map<String, Object?> toJson() => {
    'roomId': roomId,
    'phase': phase.name,
    'startedAt': startedAt.toIso8601String(),
  };

  static RunningTimer fromJson(Map<String, Object?> pJson) => RunningTimer(
    roomId: pJson['roomId']! as String,
    phase: WorkPhase.values.byName(pJson['phase']! as String),
    startedAt: DateTime.parse(pJson['startedAt']! as String),
  );
}

String dayOf(DateTime pDate) =>
    '${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}';

/// Quantité de travail d'une étape : m² peints ou posés, mètres de plinthe, passages de reprise.
double phaseQuantity(Room pRoom, WorkPhase pPhase) {
  if (pRoom.walls.length < 3 && pPhase != WorkPhase.touchUps) {
    return 0;
  }
  final rQuantity = switch (pPhase) {
    WorkPhase.touchUps => touchUpPasses(pRoom.touchUps).total.toDouble(),
    WorkPhase.ceiling => paintAreas(pRoom).ceilingM2,
    WorkPhase.walls => paintAreas(pRoom).wallsM2,
    WorkPhase.woodwork => paintAreas(pRoom).woodworkM2,
    WorkPhase.parquet => floorAreaM2(pRoom),
    WorkPhase.baseboards || WorkPhase.sealing => perimeterMm(pRoom) / 1000,
  };

  return rQuantity;
}

/// Minutes passées, en tout ou pour une pièce et une étape.
int spentMinutes(List<TimeEntry> pEntries, {String? pRoomId, WorkPhase? pPhase}) => pEntries
    .where(
      (pEntry) =>
          (pRoomId == null || pEntry.roomId == pRoomId) &&
          (pPhase == null || pEntry.phase == pPhase),
    )
    .fold(0, (pSum, pEntry) => pSum + pEntry.minutes);

/// Rythme constaté sur une étape : minutes par unité, pièces où l'étape a du temps noté.
double? minutesPerUnit(List<TimeEntry> pEntries, List<Room> pRooms, WorkPhase pPhase) {
  var vMinutes = 0;
  var vQuantity = 0.0;
  for (final vRoom in pRooms) {
    final vSpent = spentMinutes(pEntries, pRoomId: vRoom.id, pPhase: pPhase);
    final vRoomQuantity = phaseQuantity(vRoom, pPhase);
    if (vSpent > 0 && vRoomQuantity > 0) {
      vMinutes += vSpent;
      vQuantity += vRoomQuantity;
    }
  }
  final rRate = vQuantity == 0 ? null : vMinutes / vQuantity;

  return rRate;
}

/// Temps à prévoir pour une étape d'une pièce, d'après le rythme des autres ; null sans repère.
int? estimateMinutes(List<TimeEntry> pEntries, List<Room> pRooms, Room pRoom, WorkPhase pPhase) {
  final vOthers = [
    for (final vRoom in pRooms)
      if (vRoom.id != pRoom.id) vRoom,
  ];
  final vRate = minutesPerUnit(pEntries, vOthers, pPhase);
  final vQuantity = phaseQuantity(pRoom, pPhase);
  final rMinutes = vRate == null || vQuantity == 0 ? null : (vRate * vQuantity).round();

  return rMinutes;
}

/// Durée lisible : « 45 min », « 1 h 40 ».
String formatDuration(int pMinutes) {
  final vHours = pMinutes ~/ 60;
  final vRest = pMinutes % 60;
  final rText = vHours == 0
      ? '$vRest min'
      : vRest == 0
      ? '$vHours h'
      : '$vHours h ${vRest.toString().padLeft(2, '0')}';

  return rText;
}
