import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine_height.dart';
import 'stair_calculator.dart';
import 'theme.dart';
import 'plan_unit.dart';
import 'room_measure_picker.dart' show lengthText;

/// Hauteur du plancher dans une pièce haute, avec la hauteur des poteaux et l'escalier.
class MezzanineHeightCard extends StatelessWidget {
  const MezzanineHeightCard({
    super.key,
    required this.split,
    required this.postHeightMm,
    required this.onApplyPosts,
  });

  final HeightSplit split;

  /// Hauteur des poteaux saisie, comparée à celle que donne la répartition.
  final int postHeightMm;
  final VoidCallback onApplyPosts;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vUnit = PlanUnit.of(context);
    final vTheme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.heightSplitTitle, style: vTheme.textTheme.titleMedium),
            IconLine(
              Icons.height,
              vText.heightSplitFloor(
                lengthText(vText, split.floorTopMm, vUnit),
                lengthText(vText, split.structureMm, vUnit),
              ),
            ),
            IconLine(
              Icons.arrow_downward,
              vText.heightSplitBelow(lengthText(vText, split.clearBelowMm, vUnit)),
            ),
            IconLine(
              split.fits ? Icons.arrow_upward : Icons.warning_amber,
              split.fits
                  ? (split.standingAbove
                        ? vText.heightSplitStanding(lengthText(vText, split.clearAboveMm, vUnit))
                        : vText.heightSplitHabitable(lengthText(vText, split.clearAboveMm, vUnit)))
                  : vText.heightSplitTooLow(lengthText(vText, split.clearAboveMm, vUnit)),
              color: split.fits ? null : vTheme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (postHeightMm != split.clearBelowMm)
                  OutlinedButton(
                    onPressed: onApplyPosts,
                    child: Text(
                      vText.heightSplitApply(lengthText(vText, split.clearBelowMm, vUnit)),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StairCalculator(riseMm: split.floorTopMm),
                    ),
                  ),
                  child: Text(vText.heightSplitStairs),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
