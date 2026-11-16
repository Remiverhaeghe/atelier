import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/concrete.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Béton : dalle ou plots, dosage au sac, béton prêt à gâcher ou toupie.
class ConcreteCalculator extends StatefulWidget {
  const ConcreteCalculator({super.key});

  @override
  State<ConcreteCalculator> createState() => _ConcreteCalculatorState();
}

class _ConcreteCalculatorState extends State<ConcreteCalculator> {
  bool _footings = false;
  int _length = 3000;
  int _width = 2000;
  int _thickness = 100;
  int _count = 6;
  int _side = 300;
  int _depth = 500;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vM3 = _footings
        ? footingsM3(_count, _side, _depth)
        : slabM3(_length, _width, _thickness);
    final vPlan = planConcrete(vM3);
    NumberField<int> vField(String pLabel, int pInitial, ValueChanged<int> pSet) =>
        NumberField<int>(
          key: ValueKey(pLabel),
          label: pLabel,
          initial: '$pInitial',
          parse: parseWhole,
          onValue: (pValue) => setState(() => pSet(pValue)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(vText.concreteTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(vText.concreteSlab)),
              ButtonSegment(value: true, label: Text(vText.concreteFootings)),
            ],
            selected: {_footings},
            onSelectionChanged: (pValue) => setState(() => _footings = pValue.single),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.concreteVolume(formatDecimal(vM3))),
                  IconLine(
                    Icons.inventory_2_outlined,
                    vText.concreteMix(
                      vPlan.cementBags,
                      vPlan.sandKg,
                      vPlan.gravelKg,
                      vPlan.waterLitres,
                    ),
                  ),
                  IconLine(Icons.autorenew, vText.concreteBatches(vPlan.batches)),
                  IconLine(Icons.shopping_bag_outlined, vText.concreteReady(vPlan.readyBags)),
                  if (vPlan.truck) IconLine(Icons.local_shipping_outlined, vText.concreteTruck),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_footings) ...[
            vField(vText.concreteCount, _count, (pValue) => _count = pValue),
            vField(vText.concreteSide, _side, (pValue) => _side = pValue),
            vField(vText.concreteDepth, _depth, (pValue) => _depth = pValue),
          ] else ...[
            vField(vText.concreteLength, _length, (pValue) => _length = pValue),
            vField(vText.concreteWidth, _width, (pValue) => _width = pValue),
            vField(vText.concreteThickness, _thickness, (pValue) => _thickness = pValue),
          ],
          const SizedBox(height: 12),
          Text(vText.concreteHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
