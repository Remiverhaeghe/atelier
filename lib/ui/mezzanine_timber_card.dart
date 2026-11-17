import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine.dart';
import '../logic/extra_items.dart';
import '../logic/mezzanine_cutting.dart';
import '../logic/mezzanine_floor.dart';
import '../logic/units.dart';
import 'mezzanine_floor_card.dart';
import 'shopping_target.dart';
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
  const MezzanineTimberCard({
    super.key,
    required this.mezzanine,
    required this.plan,
    this.panel = FloorPanel.osb3,
  });

  final Mezzanine mezzanine;
  final MezzaninePlan plan;

  /// Panneau du plancher, pour l'ajout aux courses.
  final FloorPanel panel;

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
            AddToShoppingButton(items: () => _shopping(vText)),
          ],
        ),
      ),
    );
  }

  List<ExtraItem> _shopping(AppLocalizations pText) {
    final vBeam = plan.beam;
    final vFloor = planFloor(mezzanine, panel);
    final rItems = [
      for (final vOrder in mezzanineTimber(mezzanine, plan))
        ExtraItem(
          name: pText.extraTimber(
            vOrder.section.widthMm,
            vOrder.section.heightMm,
            formatCentimetres(vOrder.stockMm),
          ),
          quantity: vOrder.bars,
        ),
      if (vBeam != null && plan.beams > 0)
        ExtraItem(
          name: pText.extraBeam(vBeam.widthMm, vBeam.heightMm, formatCentimetres(mezzanine.lengthMm)),
          quantity: plan.beams,
        ),
      ExtraItem(name: pText.extraHangers, quantity: plan.hangers),
      ExtraItem(name: pText.extraAnchors, quantity: plan.anchorsPerLedger * plan.ledgers),
      ExtraItem(name: pText.extraPostBases, quantity: plan.postsPerBeam * plan.beams),
      ExtraItem(
        name: pText.extraFloorPanels(floorPanelLabel(pText, panel), vFloor.thicknessMm),
        quantity: vFloor.panels,
      ),
      ExtraItem(name: pText.extraScrews(5, vFloor.screwLengthMm), quantity: vFloor.screws),
      ExtraItem(name: pText.extraGlue, quantity: vFloor.glueCartridges),
    ];

    return rItems;
  }
}
