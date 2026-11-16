import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/budget_schedule.dart';
import '../logic/expenses.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Échéancier : dépenses mois par mois, puis le reste étalé sur la somme mise de côté.
class BudgetScheduleCard extends StatelessWidget {
  const BudgetScheduleCard({
    super.key,
    required this.worksite,
    required this.planned,
    required this.onChanged,
    this.now,
  });

  final Worksite worksite;
  final double planned;
  final ValueChanged<Worksite> onChanged;

  /// Mois de départ de l'échéancier ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSpent = spentByMonth(worksite.expenses);
    final vLeft = budgetLeft(planned, worksite.expenses);
    final vMonthly = worksite.monthlyBudget ?? 0;
    final vSchedule = remainingSchedule(vLeft, vMonthly, now ?? DateTime.now());
    final vHighest = vSpent.fold(
      0.0,
      (pMax, pMonth) => pMonth.amount > pMax ? pMonth.amount : pMax,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.scheduleTitle, style: vTheme.textTheme.titleMedium),
            for (final vMonth in vSpent) ...[
              const SizedBox(height: 6),
              Text(vText.scheduleSpent(monthLabel(vMonth.month), formatEuros(vMonth.amount))),
              LinearProgressIndicator(value: vHighest > 0 ? vMonth.amount / vHighest : 0),
            ],
            NumberField<double>(
              label: vText.scheduleMonthly,
              initial: vMonthly > 0 ? formatDecimal(vMonthly) : '',
              parse: parseDecimal,
              onValue: (pValue) => onChanged(worksite.copyWith(monthlyBudget: pValue)),
            ),
            if (vLeft <= 0)
              IconLine(Icons.check_circle_outline, vText.scheduleDone)
            else if (vSchedule.isEmpty)
              Text(vText.scheduleHelp, style: vTheme.textTheme.bodySmall)
            else ...[
              BigFigure(vText.schedulePaidBy(monthLabel(vSchedule.last.month))),
              for (final vMonth in vSchedule)
                IconLine(
                  Icons.event_outlined,
                  vText.scheduleMonth(monthLabel(vMonth.month), formatEuros(vMonth.amount)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
