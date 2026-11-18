import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/window_sealing.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Étanchéité de la fenêtre posée : mousse, mastic, adhésif pare-vapeur, appui, et la coupe
/// du tableau en relief pour voir où va chaque couche.
class WindowSealingCard extends StatelessWidget {
  const WindowSealingCard({super.key, required this.sealing});

  final WindowSealing sealing;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vFoam = sealing.foam;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.sealingTitle, style: vTheme.textTheme.titleMedium),
            Text(vText.sealingGoal, style: vTheme.textTheme.bodySmall),
            AspectRatio(
              aspectRatio: 1.5,
              child: Sketch3D(
                parts: [
                  Prism.box(0, 40, 0, 40, 0, 30, role: PartRole.board),
                  Prism.box(10, 30, 0, 40, 32, 52),
                  Prism.box(12, 28, 0, 40, 30, 32, role: PartRole.highlight),
                  Prism.box(7, 10, 0, 40, 28, 34, role: PartRole.glass),
                  Prism.box(30, 31, 0, 40, 24, 40, role: PartRole.highlight),
                ],
                callouts: [
                  _label(0, 15, vText.sealingOutside, const Offset(-40, 0)),
                  _label(40, 15, vText.sealingInside, const Offset(40, 30)),
                  _label(20, 31, vText.sealingFoamLabel, const Offset(10, 60)),
                  _label(8, 34, vText.sealingMasticLabel, const Offset(-50, -50)),
                  _label(31, 40, vText.sealingTapeLabel, const Offset(70, -40)),
                ],
              ),
            ),
            if (vFoam == null)
              IconLine(Icons.warning_amber, vText.sealingNoFoam, color: vTheme.colorScheme.error)
            else
              IconLine(
                Icons.water_drop_outlined,
                vText.sealingFoam(vFoam.$1, vFoam.$2, sealing.foamM, sealing.foamRolls),
              ),
            IconLine(
              Icons.format_paint_outlined,
              vText.sealingOutsideMastic(sealing.outsideSealantM, sealing.outsideCartridges),
            ),
            IconLine(
              Icons.window_outlined,
              vText.sealingGlazing(sealing.glazingSealantM, sealing.glazingCartridges),
            ),
            IconLine(
              Icons.layers_outlined,
              vText.sealingTape(sealing.vapourTapeM, sealing.vapourTapeRolls),
            ),
            IconLine(Icons.south_east, vText.sealingSill(sillSlopePercent, dripOverhangMm ~/ 10)),
            Text(vText.sealingSteps, style: vTheme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Étiquette posée sur la face avant de la coupe.
Callout _label(double pX, double pZ, String pText, Offset pShift) =>
    (at: (x: pX, y: 0, z: pZ), text: pText, shift: pShift);
