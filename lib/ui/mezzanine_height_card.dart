import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine.dart';
import '../logic/mezzanine_height.dart';
import '../logic/units.dart';
import 'stair_calculator.dart';
import 'theme.dart';

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
                formatCentimetres(split.floorTopMm),
                formatCentimetres(split.structureMm),
              ),
            ),
            IconLine(
              Icons.arrow_downward,
              vText.heightSplitBelow(formatCentimetres(split.clearBelowMm)),
            ),
            IconLine(
              split.fits ? Icons.arrow_upward : Icons.warning_amber,
              split.fits
                  ? (split.standingAbove
                        ? vText.heightSplitStanding(formatCentimetres(split.clearAboveMm))
                        : vText.heightSplitHabitable(formatCentimetres(split.clearAboveMm)))
                  : vText.heightSplitTooLow(formatCentimetres(split.clearAboveMm)),
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
                    child: Text(vText.heightSplitApply(formatCentimetres(split.clearBelowMm))),
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
