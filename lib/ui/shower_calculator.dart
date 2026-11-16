import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bathroom.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Douche de plain-pied : pente, hauteur à réserver et étanchéité sous carrelage.
class ShowerCalculator extends StatefulWidget {
  const ShowerCalculator({super.key});

  @override
  State<ShowerCalculator> createState() => _ShowerCalculatorState();
}

class _ShowerCalculatorState extends State<ShowerCalculator> {
  Shower _shower = (
    widthMm: 1200,
    depthMm: 900,
    drain: DrainKind.centre,
    siphonMm: 80,
    pipeMm: 2500,
    walls: 3,
  );

  void _set({int? pWidth, int? pDepth, DrainKind? pDrain, int? pSiphon, int? pPipe, int? pWalls}) =>
      setState(
        () => _shower = (
          widthMm: pWidth ?? _shower.widthMm,
          depthMm: pDepth ?? _shower.depthMm,
          drain: pDrain ?? _shower.drain,
          siphonMm: pSiphon ?? _shower.siphonMm,
          pipeMm: pPipe ?? _shower.pipeMm,
          walls: pWalls ?? _shower.walls,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = showerPlan(_shower);
    NumberField<int> vField(String pLabel, int pInitial, ValueChanged<int> pSet) =>
        NumberField<int>(label: pLabel, initial: '$pInitial', parse: parseWhole, onValue: pSet);

    return Scaffold(
      appBar: AppBar(title: Text(vText.showerTitle)),
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
                  BigFigure(vText.showerEdge(vPlan.edgeLevelMm)),
                  IconLine(Icons.water_drop_outlined, vText.showerDrain(vPlan.drainLevelMm)),
                  IconLine(
                    Icons.trending_down,
                    vText.showerSlope(vPlan.riseMm, formatCentimetres(vPlan.runMm)),
                  ),
                  IconLine(
                    Icons.format_paint_outlined,
                    vText.showerSpec(
                      formatDecimal(vPlan.specFloorM2),
                      formatDecimal(vPlan.specWallM2),
                    ),
                  ),
                  IconLine(Icons.linear_scale, vText.showerBand(formatDecimal(vPlan.cornerBandM))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<DrainKind>(
            segments: [
              ButtonSegment(value: DrainKind.centre, label: Text(vText.showerCentre)),
              ButtonSegment(value: DrainKind.channel, label: Text(vText.showerChannel)),
            ],
            selected: {_shower.drain},
            onSelectionChanged: (pDrain) => _set(pDrain: pDrain.single),
          ),
          vField(vText.showerWidth, _shower.widthMm, (pValue) => _set(pWidth: pValue)),
          vField(vText.showerDepth, _shower.depthMm, (pValue) => _set(pDepth: pValue)),
          vField(vText.showerSiphon, _shower.siphonMm, (pValue) => _set(pSiphon: pValue)),
          vField(vText.showerPipe, _shower.pipeMm, (pValue) => _set(pPipe: pValue)),
          const SizedBox(height: 8),
          Text(vText.showerWalls),
          SegmentedButton<int>(
            segments: [
              for (final vWalls in [1, 2, 3]) ButtonSegment(value: vWalls, label: Text('$vWalls')),
            ],
            selected: {_shower.walls},
            onSelectionChanged: (pWalls) => _set(pWalls: pWalls.single),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.lightbulb_outline, vText.showerTip),
          Text(vText.showerHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
