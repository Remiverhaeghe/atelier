import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine_floor.dart';
import '../logic/stair_design.dart';
import '../logic/stair_railing.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Garde-corps et main courante de l'escalier, selon les côtés dans le vide.
class StairRailingCard extends StatelessWidget {
  const StairRailingCard({
    super.key,
    required this.design,
    required this.riseMm,
    required this.openSides,
    required this.onOpenSides,
  });

  final StairDesign design;
  final int riseMm;
  final int openSides;
  final ValueChanged<int> onOpenSides;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRailing = planStairRailing(design, riseMm, pOpenSides: openSides);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.stairRailTitle, style: vTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 0, label: Text(vText.stairRailWalls)),
                ButtonSegment(value: 1, label: Text(vText.stairRailOneSide)),
                ButtonSegment(value: 2, label: Text(vText.stairRailTwoSides)),
              ],
              selected: {vRailing.openSides},
              onSelectionChanged: (pSelection) => onOpenSides(pSelection.first),
            ),
            const SizedBox(height: 8),
            if (vRailing.openSides > 0) ...[
              IconLine(
                Icons.fence,
                vText.stairRailGuard(
                  vRailing.openSides,
                  formatCentimetres(vRailing.lengthMm),
                  vRailing.posts,
                  vRailing.balusters,
                ),
              ),
            ],
            IconLine(
              Icons.back_hand_outlined,
              vText.stairRailHandrail(
                formatCentimetres(vRailing.handrailMm),
                formatCentimetres(stairRailHeightMm),
              ),
            ),
            Text(
              vText.stairRailRules(formatCentimetres(guardrailMaxGapMm)),
              style: vTheme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
