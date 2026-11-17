import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/blown_insulation.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String blownMaterialLabel(AppLocalizations pText, BlownMaterial pMaterial) => switch (pMaterial) {
  BlownMaterial.glassWool => pText.blownGlass,
  BlownMaterial.rockWool => pText.blownRock,
  BlownMaterial.cellulose => pText.blownCellulose,
};

/// Laine soufflée en combles perdus : épaisseur à souffler, sacs et piges.
class BlownInsulationCalculator extends StatefulWidget {
  const BlownInsulationCalculator({super.key});

  @override
  State<BlownInsulationCalculator> createState() => _BlownInsulationCalculatorState();
}

class _BlownInsulationCalculatorState extends State<BlownInsulationCalculator> {
  BlownMaterial _material = BlownMaterial.glassWool;
  double _area = 60;
  double _target = atticTargetR;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planBlown(_area, _material, pTargetR: _target);

    return Scaffold(
      appBar: AppBar(title: Text(vText.blownTitle)),
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
                  BigFigure(vText.blownBags(vPlan.bags)),
                  IconLine(
                    Icons.height,
                    vText.blownThickness(
                      formatCentimetres(vPlan.blownMm),
                      formatCentimetres(vPlan.settledMm),
                    ),
                  ),
                  IconLine(Icons.straighten, vText.blownRulers(vPlan.rulers)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BlownMaterial>(
            initialValue: _material,
            decoration: InputDecoration(labelText: vText.blownMaterial),
            items: [
              for (final vMaterial in BlownMaterial.values)
                DropdownMenuItem(
                  value: vMaterial,
                  child: Text(blownMaterialLabel(vText, vMaterial)),
                ),
            ],
            onChanged: (pMaterial) => setState(() => _material = pMaterial!),
          ),
          NumberField<double>(
            label: vText.blownArea,
            initial: formatDecimal(_area),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _area = pValue),
          ),
          NumberField<double>(
            label: vText.blownTarget,
            initial: formatDecimal(_target),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _target = pValue),
          ),
          const SizedBox(height: 12),
          Text(vText.blownHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
