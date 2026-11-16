import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/roofing.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String roofCoveringLabel(AppLocalizations pText, RoofCovering pCovering) => switch (pCovering) {
  RoofCovering.interlockingTile => pText.roofTileInterlocking,
  RoofCovering.flatTile => pText.roofTileFlat,
  RoofCovering.slate => pText.roofSlate,
};

/// Charpente et couverture d'un pan de toit.
class RoofingCalculator extends StatefulWidget {
  const RoofingCalculator({super.key});

  @override
  State<RoofingCalculator> createState() => _RoofingCalculatorState();
}

class _RoofingCalculatorState extends State<RoofingCalculator> {
  var _pan = const RoofPan();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = roofNeeds(_pan);
    void vSet(RoofPan pPan) => setState(() => _pan = pPan);

    return Scaffold(
      appBar: AppBar(title: Text(vText.roofingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.roofCoverings(vNeeds.coverings, roofCoveringLabel(vText, _pan.covering))),
                  Text(vText.roofArea(formatSquareMetres(vNeeds.areaM2))),
                  IconLine(
                    Icons.view_week_outlined,
                    vText.roofRafters(vNeeds.rafters, formatCentimetres(vNeeds.rafterLengthMm)),
                  ),
                  IconLine(Icons.vertical_align_center, vText.roofCounterBattens(vNeeds.counterBattens)),
                  IconLine(
                    Icons.table_rows_outlined,
                    vText.roofBattens(vNeeds.battens, vNeeds.battenRows),
                  ),
                  IconLine(Icons.horizontal_rule, vText.roofRidge(vNeeds.ridgePieces)),
                  IconLine(Icons.border_left, vText.roofVerge(vNeeds.vergePieces)),
                  IconLine(Icons.layers_outlined, vText.roofMembrane(vNeeds.membraneRolls)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<RoofCovering>(
            initialValue: _pan.covering,
            decoration: InputDecoration(labelText: vText.roofCovering),
            items: [
              for (final vCovering in RoofCovering.values)
                DropdownMenuItem(value: vCovering, child: Text(roofCoveringLabel(vText, vCovering))),
            ],
            onChanged: (pCovering) => vSet(_pan.copyWith(covering: pCovering)),
          ),
          NumberField<int>(
            label: vText.roofLength,
            initial: formatCentimetres(_pan.lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_pan.copyWith(lengthMm: pValue)),
          ),
          NumberField<int>(
            label: vText.roofRafterLength,
            initial: formatCentimetres(_pan.rafterMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_pan.copyWith(rafterMm: pValue)),
          ),
          NumberField<int>(
            label: vText.roofSpacing,
            initial: formatCentimetres(_pan.spacingMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_pan.copyWith(spacingMm: pValue)),
          ),
          NumberField<int>(
            label: vText.roofOverhang,
            initial: formatCentimetres(_pan.overhangMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_pan.copyWith(overhangMm: pValue)),
          ),
          const SizedBox(height: 12),
          IconLine(AtelierIcons.warning, vText.roofSafety),
          Text(vText.roofHintValues, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
