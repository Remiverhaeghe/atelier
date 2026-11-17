import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/turning_stair.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Escalier droit, quart tournant ou demi-tournant : emprise au sol et marches balancées.
class TurningStairCard extends StatelessWidget {
  const TurningStairCard({
    super.key,
    required this.riseMm,
    required this.widthMm,
    required this.shape,
    required this.onShape,
  });

  final int riseMm;
  final int widthMm;
  final StairShape shape;
  final ValueChanged<StairShape> onShape;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vStair = designTurningStair(riseMm, shape, pWidthMm: widthMm);
    String vCm(int pMm) => formatCentimetres(pMm);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.turningTitle, style: vTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<StairShape>(
              segments: [
                ButtonSegment(value: StairShape.straight, label: Text(vText.turningStraight)),
                ButtonSegment(value: StairShape.quarterTurn, label: Text(vText.turningQuarter)),
                ButtonSegment(value: StairShape.halfTurn, label: Text(vText.turningHalf)),
              ],
              selected: {shape},
              onSelectionChanged: (pSelection) => onShape(pSelection.first),
            ),
            const SizedBox(height: 8),
            IconLine(
              Icons.crop_free,
              vText.turningFootprint(
                vCm(vStair.footprintLengthMm),
                vCm(vStair.footprintWidthMm),
              ),
            ),
            if (shape != StairShape.straight) ...[
              IconLine(
                Icons.turn_right,
                vText.turningFlights(vCm(vStair.firstFlightMm), vCm(vStair.secondFlightMm)),
              ),
              IconLine(
                Icons.rotate_right,
                vText.turningTreads(vStair.turningTreads, vStair.balancedTreads),
              ),
              Text(vText.turningHint, style: vTheme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
