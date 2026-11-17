import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/floor_opening.dart';
import '../logic/mezzanine.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Trémie d'escalier dans le plancher de la mezzanine : solives coupées et renforts.
class FloorOpeningCard extends StatelessWidget {
  const FloorOpeningCard({
    super.key,
    required this.floor,
    required this.widthMm,
    required this.lengthMm,
  });

  final Mezzanine floor;
  final int widthMm;
  final int lengthMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planOpening(floor, widthMm, lengthMm);
    final vHeader = vPlan.header;
    final vTrimmer = vPlan.trimmer;
    final vEmpty = widthMm <= 0 || lengthMm <= 0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.stairwellTitle, style: vTheme.textTheme.titleMedium),
            if (vEmpty)
              Text(vText.stairwellHint, style: vTheme.textTheme.bodySmall)
            else if (vPlan.tooLong)
              IconLine(Icons.warning_amber, vText.stairwellTooLong, color: vTheme.colorScheme.error)
            else ...[
              IconLine(
                Icons.content_cut,
                vText.stairwellCut(vPlan.cutJoists, formatCentimetres(vPlan.tailLengthMm)),
              ),
              IconLine(
                Icons.horizontal_rule,
                vHeader == null
                    ? vText.stairwellNoSection
                    : vText.stairwellHeader(vHeader.widthMm, vHeader.heightMm),
              ),
              IconLine(
                Icons.view_week_outlined,
                vTrimmer == null
                    ? vText.stairwellNoSection
                    : vText.stairwellTrimmers(vTrimmer.widthMm, vTrimmer.heightMm),
              ),
              IconLine(Icons.hardware_outlined, vText.stairwellHangers(vPlan.hangers)),
            ],
          ],
        ),
      ),
    );
  }
}
