import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine.dart';
import '../logic/mezzanine_cutting.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Longueurs à couper, regroupées : « 1 × 300 cm, 9 × 200 cm ».
String groupedPieces(List<int> pPieces) {
  final vCounts = <int, int>{};
  for (final vPiece in pPieces) {
    vCounts[vPiece] = (vCounts[vPiece] ?? 0) + 1;
  }
  final rText = [
    for (final vEntry in vCounts.entries) '${vEntry.value} × ${formatCentimetres(vEntry.key)} cm',
  ].join(', ');

  return rText;
}

/// Bois à acheter pour la mezzanine, longueurs du commerce et coupes.
class MezzanineTimberCard extends StatelessWidget {
  const MezzanineTimberCard({super.key, required this.mezzanine, required this.plan});

  final Mezzanine mezzanine;
  final MezzaninePlan plan;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vBeam = plan.beam;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.timberTitle, style: vTheme.textTheme.titleMedium),
            for (final vOrder in mezzanineTimber(mezzanine, plan)) ...[
              IconLine(
                Icons.carpenter_outlined,
                vText.timberOrder(
                  vOrder.bars,
                  vOrder.section.widthMm,
                  vOrder.section.heightMm,
                  formatCentimetres(vOrder.stockMm),
                ),
              ),
              IconLine(Icons.content_cut, vText.timberPieces(groupedPieces(vOrder.pieces))),
              if (vOrder.tooLong > 0)
                IconLine(
                  Icons.warning_amber,
                  vText.timberTooLong(vOrder.tooLong),
                  color: vTheme.colorScheme.error,
                ),
            ],
            if (vBeam != null && plan.beams > 0)
              IconLine(
                Icons.straighten,
                vText.timberBeam(plan.beams, formatCentimetres(mezzanine.lengthMm)),
              ),
          ],
        ),
      ),
    );
  }
}
