import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/lighting.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String lightUseLabel(AppLocalizations pText, LightUse pUse) => switch (pUse) {
  LightUse.corridor => pText.lightUseCorridor,
  LightUse.living => pText.lightUseLiving,
  LightUse.bathroom => pText.lightUseBathroom,
  LightUse.kitchen => pText.lightUseKitchen,
  LightUse.workshop => pText.lightUseWorkshop,
};

/// Éclairer une pièce : nombre de lampes, quadrillage et puissance.
class LightingCalculator extends StatefulWidget {
  const LightingCalculator({super.key});

  @override
  State<LightingCalculator> createState() => _LightingCalculatorState();
}

class _LightingCalculatorState extends State<LightingCalculator> {
  var _lengthMm = 8000;
  var _widthMm = 6000;
  var _heightMm = 5000;
  var _use = LightUse.living;
  var _lampLumens = 3000;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planLighting(
      pLengthMm: _lengthMm,
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pUse: _use,
      pLampLumens: _lampLumens,
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.lightingTitle)),
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
                  BigFigure(vText.lightingLamps(vPlan.lamps, _lampLumens)),
                  IconLine(
                    Icons.grid_on,
                    vText.lightingGrid(
                      vPlan.columns,
                      vPlan.rows,
                      formatCentimetres(vPlan.spacingMm),
                    ),
                  ),
                  IconLine(Icons.wb_sunny_outlined, vText.lightingLumens(vPlan.lumens, _use.lux)),
                  IconLine(Icons.bolt, vText.lightingWatts(vPlan.watts)),
                  Text(vText.lightingHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LightUse>(
            initialValue: _use,
            decoration: InputDecoration(labelText: vText.lightingUse),
            items: [
              for (final vUse in LightUse.values)
                DropdownMenuItem(value: vUse, child: Text(lightUseLabel(vText, vUse))),
            ],
            onChanged: (pUse) => setState(() => _use = pUse!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: [
              for (final vLumens in lampLumensChoices)
                ButtonSegment(value: vLumens, label: Text(vText.lightingLumenChoice(vLumens))),
            ],
            selected: {_lampLumens},
            onSelectionChanged: (pSelection) => setState(() => _lampLumens = pSelection.first),
          ),
          NumberField(
            label: vText.largeRoomLength,
            initial: formatCentimetres(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          NumberField(
            label: vText.largeRoomWidth,
            initial: formatCentimetres(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.lightingHeight,
            initial: formatCentimetres(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
        ],
      ),
    );
  }
}
