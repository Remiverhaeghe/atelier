import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/diy_or_pro.dart';
import '../logic/expenses.dart';
import '../logic/real_cost.dart';
import '../logic/time_tracking.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'planning_card.dart';
import 'theme.dart';

/// Coût réel : le temps noté par étape face à la main-d'œuvre d'un artisan, au taux horaire
/// saisi par l'utilisateur. Aucun taux n'est proposé, pour ne rien présenter comme officiel.
class RealCostCard extends StatefulWidget {
  const RealCostCard({super.key, required this.entries, this.expenses = const []});

  final List<TimeEntry> entries;
  final List<Expense> expenses;

  @override
  State<RealCostCard> createState() => _RealCostCardState();
}

class _RealCostCardState extends State<RealCostCard> {
  var _rate = 0.0;
  var _speed = beginnerFactor;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vCost = realCost(widget.entries, _rate, pSpeedFactor: _speed);
    final vMaterial = spentTotal(widget.expenses);

    return Card(
      margin: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.realCostTitle, style: vTheme.textTheme.titleMedium),
            Text(vText.realCostIntro, style: vTheme.textTheme.bodySmall),
            NumberField<double>(
              label: vText.realCostRate,
              initial: '',
              parse: parseDecimal,
              onValue: (pValue) => setState(() => _rate = pValue),
            ),
            NumberField<double>(
              label: vText.realCostSpeed,
              initial: formatDecimal(beginnerFactor),
              parse: parseDecimal,
              onValue: (pValue) => setState(() => _speed = pValue),
            ),
            const SizedBox(height: 8),
            if (_rate <= 0)
              IconLine(Icons.info_outline, vText.realCostNoRate)
            else ...[
              BigFigure(vText.realCostTotal(formatDecimal(vCost.proEuros.roundToDouble()))),
              IconLine(
                Icons.schedule,
                vText.realCostPerHour(formatDecimal(vCost.savedPerHour.roundToDouble())),
              ),
              for (final vPhase in vCost.phases)
                IconLine(
                  Icons.timer_outlined,
                  vText.realCostPhase(
                    phaseLabel(vText, vPhase.phase),
                    formatDuration(vPhase.minutes),
                    formatDecimal(vPhase.proEuros.roundToDouble()),
                  ),
                ),
            ],
            if (vMaterial > 0)
              IconLine(
                Icons.receipt_long_outlined,
                vText.realCostMaterial(formatDecimal(vMaterial.roundToDouble())),
              ),
          ],
        ),
      ),
    );
  }
}
