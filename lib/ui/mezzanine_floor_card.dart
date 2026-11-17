import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine.dart';
import '../logic/mezzanine_floor.dart';
import '../logic/units.dart';
import 'theme.dart';

String floorPanelLabel(AppLocalizations pText, FloorPanel pPanel) => switch (pPanel) {
  FloorPanel.osb3 => pText.floorPanelOsb,
  FloorPanel.particleP5 => pText.floorPanelP5,
};

/// Plancher et garde-corps d'une mezzanine, sous sa structure.
class MezzanineFloorCard extends StatelessWidget {
  const MezzanineFloorCard({
    super.key,
    required this.mezzanine,
    required this.panel,
    required this.stairOpeningMm,
  });

  final Mezzanine mezzanine;
  final FloorPanel panel;
  final int stairOpeningMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vFloor = planFloor(mezzanine, panel);
    final vRail = planGuardrail(openEdgeMm(mezzanine, stairOpeningMm));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.floorTitle, style: vTheme.textTheme.titleMedium),
            IconLine(
              Icons.grid_view,
              vText.floorPanels(vFloor.panels, floorPanelLabel(vText, panel), vFloor.thicknessMm),
            ),
            IconLine(
              Icons.hardware_outlined,
              vText.floorScrews(vFloor.screws, vFloor.screwLengthMm),
            ),
            IconLine(Icons.water_drop_outlined, vText.floorGlue(vFloor.glueCartridges)),
            IconLine(Icons.tips_and_updates_outlined, vText.floorLaying),
            const SizedBox(height: 12),
            Text(vText.guardrailTitle, style: vTheme.textTheme.titleMedium),
            IconLine(
              Icons.fence,
              vText.guardrailLength(formatCentimetres(vRail.lengthMm), vRail.posts),
            ),
            IconLine(
              Icons.view_column_outlined,
              vText.guardrailBalusters(vRail.balusters, vRail.balusterWidthMm),
            ),
            IconLine(
              Icons.rule,
              vText.guardrailRules(
                formatCentimetres(guardrailHeightMm),
                formatCentimetres(guardrailMaxGapMm),
                formatCentimetres(guardrailClimbZoneMm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
