import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/condensation.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import 'glossary_view.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Humidité et condensation : une paroi plus froide que le point de rosée de la pièce perle,
/// puis moisit. L'écran dit si c'est le cas et quoi faire.
class CondensationCalculator extends StatefulWidget {
  const CondensationCalculator({super.key});

  @override
  State<CondensationCalculator> createState() => _CondensationCalculatorState();
}

class _CondensationCalculatorState extends State<CondensationCalculator> {
  Wall _wall = Wall.doubleGlazing;
  double _inside = 20;
  double _humidity = 60;
  double _outside = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vCheck = checkCondensation(
      pWall: _wall,
      pInsideC: _inside,
      pHumidityPercent: _humidity,
      pOutsideC: _outside,
    );
    final vMax = maxHumidityFor(_wall, _inside, _outside);
    final vError = vTheme.colorScheme.error;

    return Scaffold(
      appBar: AppBar(title: Text(vText.dewTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          DropdownButtonFormField<Wall>(
            initialValue: _wall,
            decoration: InputDecoration(labelText: vText.dewWall),
            items: [
              for (final vWall in Wall.values)
                DropdownMenuItem(value: vWall, child: Text(wallName(vText, vWall))),
            ],
            onChanged: (pWall) => setState(() => _wall = pWall ?? _wall),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.dewResult, style: vTheme.textTheme.titleMedium),
                  IconLine(
                    Icons.water_drop_outlined,
                    vText.dewPoint(formatDecimal1(vCheck.dewPointC)),
                  ),
                  IconLine(Icons.thermostat, vText.dewSurface(formatDecimal1(vCheck.surfaceC))),
                  switch (vCheck.risk) {
                    CondensationRisk.condensation => IconLine(
                      Icons.warning_amber,
                      vText.dewWet,
                      color: vError,
                    ),
                    CondensationRisk.close => IconLine(Icons.error_outline, vText.dewClose),
                    CondensationRisk.none => IconLine(Icons.check_circle_outline, vText.dewDry),
                  },
                  IconLine(Icons.opacity, vText.dewMaxHumidity(vMax.floor())),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<double>(
            label: vText.dewInside,
            initial: formatDecimal(_inside),
            parse: parseSignedDecimal,
            onValue: (pValue) => setState(() => _inside = pValue),
          ),
          NumberField<double>(
            label: vText.dewHumidity,
            initial: formatDecimal(_humidity),
            parse: (pText) {
              final vValue = parseDecimal(pText);

              return vValue != null && vValue > 0 && vValue <= 100 ? vValue : null;
            },
            onValue: (pValue) => setState(() => _humidity = pValue),
          ),
          NumberField<double>(
            label: vText.dewOutside,
            initial: formatDecimal(_outside),
            parse: parseSignedDecimal,
            onValue: (pValue) => setState(() => _outside = pValue),
          ),
          const SizedBox(height: 12),
          const TermsRow([Term.vapourBarrier]),
          IconLine(Icons.air, vText.dewVentilate),
          IconLine(Icons.layers_outlined, vText.dewVapour),
          IconLine(Icons.device_thermostat, vText.dewHeat),
          Text(vText.dewHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

String formatDecimal1(double pValue) => formatDecimal((pValue * 10).round() / 10);

String wallName(AppLocalizations pText, Wall pWall) => switch (pWall) {
  Wall.singleGlazing => pText.wallSingleGlazing,
  Wall.acrylicSheet => pText.wallAcrylic,
  Wall.doubleGlazing => pText.wallDoubleGlazing,
  Wall.bareRoof => pText.wallBareRoof,
  Wall.bareWall => pText.wallBareWall,
  Wall.insulatedWall => pText.wallInsulatedWall,
  Wall.insulatedRoof => pText.wallInsulatedRoof,
};
