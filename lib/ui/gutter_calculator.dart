import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/gutters.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Gouttière d'un pan de toit : descentes, diamètre, pente et crochets.
class GutterCalculator extends StatefulWidget {
  const GutterCalculator({super.key});

  @override
  State<GutterCalculator> createState() => _GutterCalculatorState();
}

class _GutterCalculatorState extends State<GutterCalculator> {
  int _length = 10000;
  int _depth = 5000;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planGutter(_length, _depth);

    return Scaffold(
      appBar: AppBar(title: Text(vText.gutterTitle)),
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
                  BigFigure(vText.gutterDescents(vPlan.descents, vPlan.diameterMm)),
                  IconLine(Icons.roofing_outlined, vText.gutterRoof(formatDecimal(vPlan.roofM2))),
                  IconLine(Icons.trending_down, vText.gutterDrop(vPlan.dropMm)),
                  IconLine(Icons.hardware_outlined, vText.gutterHooks(vPlan.hooks)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<int>(
            label: vText.gutterLength,
            initial: '$_length',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _length = pValue),
          ),
          NumberField<int>(
            label: vText.gutterDepth,
            initial: '$_depth',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _depth = pValue),
          ),
          const SizedBox(height: 12),
          Text(vText.gutterHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
