import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/acoustics.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Isolation phonique : cloison ou plancher de mezzanine, matériel et gestes qui comptent.
class AcousticsCalculator extends StatefulWidget {
  const AcousticsCalculator({super.key});

  @override
  State<AcousticsCalculator> createState() => _AcousticsCalculatorState();
}

class _AcousticsCalculatorState extends State<AcousticsCalculator> {
  SoundCase _case = SoundCase.partition;
  double _area = 10;
  double _perimeter = 13;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = soundPlan(_case, _area, (_perimeter * 1000).round());
    final vFloor = _case == SoundCase.mezzanineFloor;

    return Scaffold(
      appBar: AppBar(title: Text(vText.soundTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<SoundCase>(
            segments: [
              ButtonSegment(value: SoundCase.partition, label: Text(vText.soundPartition)),
              ButtonSegment(value: SoundCase.mezzanineFloor, label: Text(vText.soundFloor)),
            ],
            selected: {_case},
            onSelectionChanged: (pCase) => setState(() => _case = pCase.single),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                  IconLine(Icons.dashboard_outlined, vText.soundBoards(vPlan.boards)),
                  IconLine(Icons.texture, vText.soundWool(formatDecimal(vPlan.woolM2))),
                  IconLine(
                    Icons.linear_scale,
                    vText.soundBand(formatDecimal(vPlan.resilientBandM)),
                  ),
                  IconLine(Icons.colorize_outlined, vText.soundMastic(vPlan.mastic)),
                  if (vFloor) ...[
                    IconLine(Icons.vertical_align_bottom, vText.soundHangers(vPlan.hangers)),
                    IconLine(
                      Icons.layers_outlined,
                      vText.soundUnderlay(formatDecimal(vPlan.underlayM2)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<double>(
            label: vText.soundArea,
            initial: formatDecimal(_area),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _area = pValue),
          ),
          NumberField<double>(
            label: vText.soundPerimeter,
            initial: formatDecimal(_perimeter),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _perimeter = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(
            Icons.lightbulb_outline,
            vFloor ? vText.soundFloorTip : vText.soundPartitionTip,
          ),
          Text(vText.soundHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
