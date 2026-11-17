import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/rolling_tower.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Échafaudage roulant à louer ou monter : plancher, éléments, stabilisateurs.
class RollingTowerCard extends StatefulWidget {
  const RollingTowerCard({super.key});

  @override
  State<RollingTowerCard> createState() => _RollingTowerCardState();
}

class _RollingTowerCardState extends State<RollingTowerCard> {
  var _reachMm = 4000;
  var _base = TowerBase.narrow;
  var _outdoor = false;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planTower(pReachMm: _reachMm, pBase: _base, pOutdoor: _outdoor);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.towerTitle, style: vTheme.textTheme.titleMedium),
            NumberField(
              label: vText.towerReach,
              initial: formatCentimetres(_reachMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _reachMm = pValue),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TowerBase>(
              segments: [
                ButtonSegment(value: TowerBase.narrow, label: Text(vText.towerNarrow)),
                ButtonSegment(value: TowerBase.wide, label: Text(vText.towerWide)),
              ],
              selected: {_base},
              onSelectionChanged: (pSelection) => setState(() => _base = pSelection.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vText.towerOutdoor),
              value: _outdoor,
              onChanged: (pValue) => setState(() => _outdoor = pValue),
            ),
            if (vPlan.platformMm == 0)
              IconLine(Icons.check_circle_outline, vText.towerNotNeeded)
            else ...[
              IconLine(
                Icons.stairs_outlined,
                vText.towerPlatform(formatCentimetres(vPlan.platformMm), vPlan.frames),
              ),
              IconLine(
                Icons.fence_outlined,
                vText.towerGuardrail(formatCentimetres(vPlan.totalHeightMm)),
              ),
              IconLine(
                vPlan.needsStabilisers ? Icons.warning_amber : Icons.check_circle_outline,
                vPlan.needsStabilisers ? vText.towerStabilisers : vText.towerNoStabilisers,
                color: vPlan.needsStabilisers ? vTheme.colorScheme.error : null,
              ),
            ],
            if (vPlan.tooHigh)
              IconLine(
                Icons.engineering_outlined,
                vText.towerTooHigh,
                color: vTheme.colorScheme.error,
              ),
            Text(vText.towerRules, style: vTheme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
