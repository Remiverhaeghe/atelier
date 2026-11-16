/// Badges (Achievement, pour ne pas croiser le widget Badge de Flutter) : étapes franchies sur le chantier, calculées depuis son état.
library;

import 'baseboard.dart';
import 'progress.dart';
import 'shopping.dart';
import 'worksite.dart';

enum Achievement {
  /// Une première rangée de parquet posée.
  firstRow,

  /// Une pièce finie : tout ce qui était prévu dedans est fait.
  roomDone,

  /// Toutes les plinthes du chantier coupées.
  allBaseboardsCut,

  /// Dix reprises finies.
  tenTouchUps,

  /// Un objectif du jour atteint.
  firstGoal,

  /// Cinq objectifs du jour atteints.
  fiveGoals,

  /// Tous les prix saisis : le budget est complet.
  fullBudget,
}

/// Badges gagnés, dans l'ordre de l'énumération.
Set<Achievement> earnedAchievements(Worksite pWorksite) {
  final vRooms = pWorksite.rooms;
  final vPieces = [
    for (final vRoom in vRooms) (room: vRoom, count: baseboardPieces(vRoom, vRoom.baseboard).length),
  ];
  final vGoals = pWorksite.goalsReached + (pWorksite.goal?.reached(pWorksite) ?? false ? 1 : 0);
  final vLines = shoppingList(pWorksite);
  final vDoneTouchUps = vRooms.fold(
    0,
    (pSum, pRoom) => pSum + pRoom.touchUps.where((pTouchUp) => pTouchUp.done).length,
  );
  final rBadges = <Achievement>{
    if (vRooms.any((pRoom) => pRoom.laidRows.isNotEmpty)) Achievement.firstRow,
    if (vRooms.any((pRoom) {
      final vProgress = roomProgress(pRoom);
      return vProgress.total > 0 && vProgress.done == vProgress.total;
    }))
      Achievement.roomDone,
    if (vPieces.any((pEntry) => pEntry.count > 0) &&
        vPieces.every(
          (pEntry) => pEntry.room.cutPieces.where((pIndex) => pIndex < pEntry.count).length == pEntry.count,
        ))
      Achievement.allBaseboardsCut,
    if (vDoneTouchUps >= 10) Achievement.tenTouchUps,
    if (vGoals >= 1) Achievement.firstGoal,
    if (vGoals >= 5) Achievement.fiveGoals,
    if (vLines.isNotEmpty && !budgetIncomplete(vLines)) Achievement.fullBudget,
  };

  return rBadges;
}
