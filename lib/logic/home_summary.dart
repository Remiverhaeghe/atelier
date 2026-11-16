/// Résumé du widget d'écran d'accueil : objectif du jour et prochaine attente.
library;

import 'goals.dart';
import 'reminders.dart';
import 'worksite.dart';

typedef HomeSummary = ({String worksite, int done, int total, int? nextWaitHours});

/// Le chantier qui a un objectif aujourd'hui, sinon le premier ; null sans chantier.
HomeSummary? homeSummary(List<Worksite> pWorksites, DateTime pNow) {
  if (pWorksites.isEmpty) {
    return null;
  }
  final vToday = goalDate(pNow);
  final vWorksite =
      pWorksites.where((pWorksite) => pWorksite.goal?.date == vToday).firstOrNull ??
      pWorksites.first;
  final vGoal = vWorksite.goal?.date == vToday ? vWorksite.goal : null;
  final vWaits = [
    for (final vReminder in vWorksite.reminders)
      if (hoursLeft(vReminder, pNow) > 0) hoursLeft(vReminder, pNow),
  ]..sort();
  final rSummary = (
    worksite: vWorksite.name,
    done: vGoal?.doneCount(vWorksite) ?? 0,
    total: vGoal?.items.length ?? 0,
    nextWaitHours: vWaits.firstOrNull,
  );

  return rSummary;
}
