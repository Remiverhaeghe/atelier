/// Objectif du jour SMART : quelques tâches précises, comptées, faisables dans la journée et datées.
library;

import 'baseboard.dart';
import 'laying_plan.dart';
import 'room.dart';
import 'worksite.dart';

/// Ce qu'une ligne d'objectif fait avancer.
enum GoalKind { touchUp, rows, pieces }

/// Une ligne de l'objectif : une reprise jusqu'à un passage, des rangées ou des morceaux précis.
class GoalItem {
  const GoalItem({
    required this.kind,
    required this.roomId,
    this.touchUpId,
    this.targetPasses = 0,
    this.numbers = const [],
  });

  final GoalKind kind;
  final String roomId;

  /// Reprise visée et passage à atteindre.
  final String? touchUpId;
  final int targetPasses;

  /// Numéros des rangées ou index des morceaux de plinthe à faire.
  final List<int> numbers;

  /// Ligne faite d'après l'état actuel de la pièce ; faite aussi si sa cible a disparu.
  bool isDone(Room? pRoom) {
    if (pRoom == null) {
      return true;
    }
    final rDone = switch (kind) {
      GoalKind.touchUp =>
        (pRoom.touchUps.where((pTouchUp) => pTouchUp.id == touchUpId).firstOrNull?.donePasses ??
                targetPasses) >=
            targetPasses,
      GoalKind.rows => numbers.every(pRoom.laidRows.contains),
      GoalKind.pieces => numbers.every(pRoom.cutPieces.contains),
    };

    return rDone;
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'roomId': roomId,
    if (touchUpId != null) 'touchUpId': touchUpId,
    if (kind == GoalKind.touchUp) 'targetPasses': targetPasses,
    if (numbers.isNotEmpty) 'numbers': numbers,
  };

  static GoalItem fromJson(Map<String, Object?> pJson) => GoalItem(
    kind: GoalKind.values.byName(pJson['kind']! as String),
    roomId: pJson['roomId']! as String,
    touchUpId: pJson['touchUpId'] as String?,
    targetPasses: (pJson['targetPasses'] as int?) ?? 0,
    numbers: [
      for (final vNumber in (pJson['numbers'] as List<Object?>?) ?? const []) vNumber! as int,
    ],
  );
}

/// Objectif d'une journée, daté au format AAAA-MM-JJ.
class DailyGoal {
  const DailyGoal({required this.date, required this.items});

  final String date;
  final List<GoalItem> items;

  int doneCount(Worksite pWorksite) =>
      items.where((pItem) => pItem.isDone(_room(pWorksite, pItem))).length;

  bool reached(Worksite pWorksite) => items.isNotEmpty && doneCount(pWorksite) == items.length;

  Map<String, Object?> toJson() => {
    'date': date,
    'items': [for (final vItem in items) vItem.toJson()],
  };

  static DailyGoal fromJson(Map<String, Object?> pJson) => DailyGoal(
    date: pJson['date']! as String,
    items: [
      for (final vItem in (pJson['items'] as List<Object?>?) ?? const [])
        GoalItem.fromJson(vItem! as Map<String, Object?>),
    ],
  );
}

Room? _room(Worksite pWorksite, GoalItem pItem) =>
    pWorksite.rooms.where((pRoom) => pRoom.id == pItem.roomId).firstOrNull;

/// Date du jour au format de l'objectif.
String goalDate(DateTime pDay) =>
    '${pDay.year.toString().padLeft(4, '0')}-${pDay.month.toString().padLeft(2, '0')}-${pDay.day.toString().padLeft(2, '0')}';

/// Rangées et morceaux proposés pour une journée : assez pour avancer, sans viser trop haut.
const rowsPerDay = 5;
const piecesPerDay = 6;
const maxGoalItems = 3;

/// Propose un objectif atteignable : une reprise, des rangées, des morceaux, dans l'ordre du chantier.
DailyGoal suggestGoal(Worksite pWorksite, DateTime pDay) {
  final vTouchUps = <GoalItem>[];
  final vRows = <GoalItem>[];
  final vPieces = <GoalItem>[];
  for (final vRoom in pWorksite.rooms) {
    for (final vTouchUp in vRoom.touchUps.where((pTouchUp) => !pTouchUp.done)) {
      vTouchUps.add(
        GoalItem(
          kind: GoalKind.touchUp,
          roomId: vRoom.id,
          touchUpId: vTouchUp.id,
          targetPasses: vTouchUp.donePasses + 1,
        ),
      );
    }
    final vPlan = planLaying(vRoom, vRoom.parquet);
    final vNextRows = [
      for (final vRow in vPlan?.rows ?? const <LayingRow>[])
        if (!vRoom.laidRows.contains(vRow.number)) vRow.number,
    ].take(rowsPerDay).toList();
    if (vNextRows.isNotEmpty) {
      vRows.add(GoalItem(kind: GoalKind.rows, roomId: vRoom.id, numbers: vNextRows));
    }
    final vPieceCount = baseboardPieces(vRoom, vRoom.baseboard).length;
    final vNextPieces = [
      for (var vIndex = 0; vIndex < vPieceCount; vIndex++)
        if (!vRoom.cutPieces.contains(vIndex)) vIndex,
    ].take(piecesPerDay).toList();
    // Des plinthes seulement une fois le parquet posé : elles se fixent par-dessus
    if (vNextPieces.isNotEmpty && vNextRows.isEmpty) {
      vPieces.add(GoalItem(kind: GoalKind.pieces, roomId: vRoom.id, numbers: vNextPieces));
    }
  }
  // Une ligne de chaque sorte si possible, puis les reprises suivantes
  final rItems = <GoalItem>[
    if (vRows.isNotEmpty) vRows.first,
    if (vPieces.isNotEmpty) vPieces.first,
    if (vTouchUps.isNotEmpty) vTouchUps.first,
  ];
  for (final vItem in vTouchUps.skip(1)) {
    if (rItems.length >= maxGoalItems) {
      break;
    }
    rItems.add(vItem);
  }

  return DailyGoal(date: goalDate(pDay), items: rItems.take(maxGoalItems).toList());
}
