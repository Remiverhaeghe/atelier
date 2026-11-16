import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/drywall.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Placo et isolation : plaques, ossature, vis, bandes, enduit, laine et résistance thermique.
class DrywallCalculator extends StatefulWidget {
  const DrywallCalculator({super.key});

  @override
  State<DrywallCalculator> createState() => _DrywallCalculatorState();
}

class _DrywallCalculatorState extends State<DrywallCalculator> {
  var _design = const DrywallDesign();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = drywallNeeds(_design);
    void vSet(DrywallDesign pDesign) => setState(() => _design = pDesign);

    return Scaffold(
      appBar: AppBar(title: Text(vText.drywallTitle)),
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
                  BigFigure(vText.drywallPlates(vNeeds.plates)),
                  IconLine(Icons.crop_free, vText.totalArea(formatDecimal(vNeeds.areaM2))),
                  IconLine(Icons.straighten, vText.drywallFrame(vNeeds.rails, vNeeds.studs)),
                  IconLine(Icons.hardware_outlined, vText.drywallScrews(vNeeds.screws)),
                  IconLine(Icons.format_paint_outlined, vText.drywallJoints(vNeeds.tapeRolls, vNeeds.fillerBags)),
                  if (vNeeds.insulationRolls > 0) ...[
                    IconLine(Icons.layers_outlined, vText.drywallInsulation(vNeeds.insulationRolls)),
                    IconLine(
                      Icons.thermostat_outlined,
                      vText.drywallResistance(formatDecimal((vNeeds.resistance * 100).round() / 100)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(vText.drywallHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.drywallPartition),
            subtitle: Text(vText.drywallPartitionHelp),
            value: _design.partition,
            onChanged: (pValue) => vSet(_design.copyWith(partition: pValue)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (vText.drywallLength, _design.lengthMm, (int pValue) => _design.copyWith(lengthMm: pValue)),
            (vText.drywallHeight, _design.heightMm, (int pValue) => _design.copyWith(heightMm: pValue)),
            (
              vText.drywallSpacing,
              _design.studSpacingMm,
              (int pValue) => _design.copyWith(studSpacingMm: pValue),
            ),
            (
              vText.drywallInsulationThickness,
              _design.insulationMm,
              (int pValue) => _design.copyWith(insulationMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          NumberField<double>(
            label: vText.drywallLambda,
            initial: formatDecimal(_design.lambda),
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(lambda: pValue)),
          ),
          NumberField<double>(
            label: vText.drywallRoll,
            initial: formatDecimal(_design.insulationRollM2),
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(insulationRollM2: pValue)),
          ),
        ],
      ),
    );
  }
}
