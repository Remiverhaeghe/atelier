import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/floor_capacity.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String floorUseLabel(AppLocalizations pText, FloorUse pUse) => switch (pUse) {
  FloorUse.living => pText.floorUseLiving,
  FloorUse.bath => pText.floorUseBath,
  FloorUse.bookcase => pText.floorUseBookcase,
  FloorUse.stove => pText.floorUseStove,
  FloorUse.veryHeavy => pText.floorUseVeryHeavy,
};

/// Ce que porte un plancher existant, d'après ses solives mesurées, et les renforts.
class FloorCapacityCalculator extends StatefulWidget {
  const FloorCapacityCalculator({super.key});

  @override
  State<FloorCapacityCalculator> createState() => _FloorCapacityCalculatorState();
}

class _FloorCapacityCalculatorState extends State<FloorCapacityCalculator> {
  var _widthMm = 63;
  var _heightMm = 175;
  var _spacingMm = 400;
  var _spanMm = 4000;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vJoist = (widthMm: _widthMm, heightMm: _heightMm);
    final vCapacity = liveCapacityKnPerM2(vJoist, _spacingMm, _spanMm);
    final vOptions = reinforcements(vJoist, _spacingMm, _spanMm);
    int vKg(double pKn) => (pKn * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(vText.floorCapacityTitle)),
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
                  BigFigure(vText.floorCapacityResult(vKg(vCapacity))),
                  for (final vUse in FloorUse.values)
                    IconLine(
                      vCapacity >= vUse.knPerM2 ? Icons.check : Icons.warning_amber,
                      vText.floorUseLine(floorUseLabel(vText, vUse), vKg(vUse.knPerM2)),
                      color: vCapacity >= vUse.knPerM2 ? null : vTheme.colorScheme.error,
                    ),
                  const SizedBox(height: 8),
                  Text(vText.floorReinforceTitle, style: vTheme.textTheme.titleSmall),
                  IconLine(Icons.view_week_outlined, vText.floorReinforceDoubled(vKg(vOptions.doubled))),
                  IconLine(Icons.add, vText.floorReinforceHalfSpacing(vKg(vOptions.halfSpacing))),
                  IconLine(Icons.vertical_align_bottom, vText.floorReinforceMidBeam(vKg(vOptions.midBeam))),
                  Text(vText.floorCapacityWarning, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: vText.floorJoistWidth,
            initial: '$_widthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.floorJoistHeight,
            initial: '$_heightMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
          NumberField(
            label: vText.mezzanineSpacing,
            initial: formatCentimetres(_spacingMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _spacingMm = pValue),
          ),
          NumberField(
            label: vText.floorJoistSpan,
            initial: formatCentimetres(_spanMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _spanMm = pValue),
          ),
        ],
      ),
    );
  }
}
