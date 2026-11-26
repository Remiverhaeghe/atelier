/// Bilan de fin de chantier : coût prévu et réel, temps, chutes gardées, reprises et leçons.
library;

import 'day_log.dart';
import 'expenses.dart';
import 'planning.dart';
import 'shopping.dart';
import 'time_tracking.dart';
import 'worksite.dart';

typedef WorksiteReview = ({
  double plannedCost,
  bool plannedIncomplete,
  double spentCost,
  double? overrunPercent,
  int minutes,
  WorkPhase? longestPhase,
  int offcutsKept,
  int touchUpsDone,
  int touchUpsTotal,
  int journalEntries,
  int daysWorked,
});

/// Bilan chiffré du chantier ; le dépassement n'a de sens qu'avec un budget prévu.
WorksiteReview reviewWorksite(Worksite pWorksite) {
  final vLines = shoppingList(pWorksite);
  final vPlanned = budgetTotal(vLines);
  final vSpent = spentTotal(pWorksite.expenses);
  WorkPhase? vLongest;
  var vLongestMinutes = 0;
  for (final vPhase in WorkPhase.values) {
    final vMinutes = spentMinutes(pWorksite.timeEntries, pPhase: vPhase);
    if (vMinutes > vLongestMinutes) {
      vLongestMinutes = vMinutes;
      vLongest = vPhase;
    }
  }
  final vTouchUps = [for (final vRoom in pWorksite.rooms) ...vRoom.touchUps];
  final rReview = (
    plannedCost: vPlanned,
    plannedIncomplete: budgetIncomplete(vLines),
    spentCost: vSpent,
    overrunPercent: vPlanned <= 0 ? null : (vSpent - vPlanned) / vPlanned * 100,
    minutes: spentMinutes(pWorksite.timeEntries),
    longestPhase: vLongest,
    offcutsKept: pWorksite.offcuts.length,
    touchUpsDone: vTouchUps.where((pTouchUp) => pTouchUp.done).length,
    touchUpsTotal: vTouchUps.length,
    journalEntries: pWorksite.journal.length,
    daysWorked: daysWorked(
      dayLines(
        notes: pWorksite.dayNotes,
        timeEntries: pWorksite.timeEntries,
        journal: pWorksite.journal,
      ),
    ),
  );

  return rReview;
}
