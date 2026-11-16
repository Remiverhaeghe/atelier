import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/doors.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Porte intérieure à changer : bloc-porte standard, jeu à reprendre, sens d'ouverture.
class DoorCalculator extends StatefulWidget {
  const DoorCalculator({super.key});

  @override
  State<DoorCalculator> createState() => _DoorCalculatorState();
}

class _DoorCalculatorState extends State<DoorCalculator> {
  int _width = 900;
  int _height = 2120;
  int _wall = 72;
  DoorHand _hand = DoorHand.pushRight;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vMatch = matchDoor(pOpeningWidthMm: _width, pOpeningHeightMm: _height, pWallMm: _wall);
    final vLeaf = vMatch.leafWidthMm;

    return Scaffold(
      appBar: AppBar(title: Text(vText.doorTitle)),
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
                  if (vLeaf == null)
                    IconLine(AtelierIcons.warning, vText.doorTooNarrow)
                  else ...[
                    BigFigure(
                      vText.doorLeaf(formatCentimetres(vLeaf), formatCentimetres(doorLeafHeightMm)),
                    ),
                    Text(
                      _hand == DoorHand.pushRight ? vText.doorPushRight : vText.doorPushLeft,
                      style: vTheme.textTheme.titleMedium,
                    ),
                    IconLine(Icons.swap_horiz, vText.doorWidthGap(formatCentimetres(vMatch.widthGapMm))),
                  ],
                  IconLine(
                    vMatch.heightFits ? Icons.check : AtelierIcons.warning,
                    vMatch.heightFits
                        ? vText.doorHeightOk(formatCentimetres(vMatch.heightGapMm))
                        : vText.doorHeightShort(formatCentimetres(-vMatch.heightGapMm)),
                  ),
                  if (vMatch.adjustableFrame)
                    IconLine(Icons.width_wide, vText.doorAdjustable(formatCentimetres(_wall))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<int>(
            label: vText.doorOpeningWidth,
            initial: formatCentimetres(_width),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _width = pValue),
          ),
          NumberField<int>(
            label: vText.doorOpeningHeight,
            initial: formatCentimetres(_height),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _height = pValue),
          ),
          NumberField<int>(
            label: vText.doorWall,
            initial: formatCentimetres(_wall),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _wall = pValue),
          ),
          const SizedBox(height: 12),
          SegmentedButton<DoorHand>(
            segments: [
              ButtonSegment(value: DoorHand.pushLeft, label: Text(vText.doorHandLeft)),
              ButtonSegment(value: DoorHand.pushRight, label: Text(vText.doorHandRight)),
            ],
            selected: {_hand},
            onSelectionChanged: (pChoice) => setState(() => _hand = pChoice.single),
          ),
          const SizedBox(height: 8),
          IconLine(Icons.info_outline, vText.doorHandHowTo),
          IconLine(Icons.straighten, vText.doorMeasureHowTo),
        ],
      ),
    );
  }
}
