import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/high_paint.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'theme.dart';

String highAccessLabel(AppLocalizations pText, HighAccessPlan pPlan) {
  final vPole = formatDecimal((pPlan.poleMm ?? 0) / 1000);
  final rLabel = switch (pPlan.access) {
    HighAccess.roller => pText.highAccessRoller,
    HighAccess.telescopicPole => pText.highAccessPole(vPole),
    HighAccess.poleAndStepladder => pText.highAccessPoleLadder(vPole),
    HighAccess.scaffold => pText.highAccessScaffold,
  };

  return rLabel;
}

String highStepLabel(AppLocalizations pText, HighPaintStep pStep) => switch (pStep) {
  HighPaintStep.protect => pText.highStepProtect,
  HighPaintStep.ceilingFirst => pText.highStepCeilingFirst,
  HighPaintStep.cutInTop => pText.highStepCutInTop,
  HighPaintStep.verticalBands => pText.highStepVerticalBands,
  HighPaintStep.wetEdge => pText.highStepWetEdge,
  HighPaintStep.moveAlong => pText.highStepMoveAlong,
  HighPaintStep.noStopMidWall => pText.highStepNoStopMidWall,
  HighPaintStep.secondCoat => pText.highStepSecondCoat,
};

/// Peindre une grande hauteur : matériel, quantités et ordre de travail sans reprise.
class HighPaintCalculator extends StatefulWidget {
  const HighPaintCalculator({super.key});

  @override
  State<HighPaintCalculator> createState() => _HighPaintCalculatorState();
}

class _HighPaintCalculatorState extends State<HighPaintCalculator> {
  var _perimeter = 16000;
  var _height = 5000;
  var _ceiling = 16.0;
  var _openings = 4.0;
  var _coats = 2;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vAccess = highAccess(_height);
    final vPlan = highPaintPlan(
      pPerimeterMm: _perimeter,
      pHeightMm: _height,
      pCeilingM2: _ceiling,
      pOpeningsM2: _openings,
      pCoats: _coats,
    );
    final vSteps = highPaintSteps(vAccess.access);
    final vWallLine = vText.highPaintWall(
      formatDecimal(vPlan.wallM2),
      formatDecimal(vPlan.wallLitres),
      vPlan.wallCans,
    );
    final vCeilingLine = vText.highPaintCeilingLine(
      formatDecimal(vPlan.ceilingM2),
      formatDecimal(vPlan.ceilingLitres),
      vPlan.ceilingCans,
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.highPaintTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.highPaintIntro, style: vTheme.textTheme.bodyMedium),
          NumberField<int>(
            label: vText.highPaintPerimeter,
            initial: formatCentimetres(_perimeter),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _perimeter = pValue),
          ),
          NumberField<int>(
            label: vText.highPaintHeight,
            initial: formatCentimetres(_height),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _height = pValue),
          ),
          NumberField<double>(
            label: vText.highPaintCeiling,
            initial: formatDecimal(_ceiling),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _ceiling = pValue),
          ),
          NumberField<double>(
            label: vText.highPaintOpenings,
            initial: formatDecimal(_openings),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _openings = pValue),
          ),
          NumberField<int>(
            label: vText.highPaintCoats,
            initial: '$_coats',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _coats = pValue),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(highAccessLabel(vText, vAccess)),
                  if (vAccess.access == HighAccess.scaffold)
                    IconLine(
                      AtelierIcons.warning,
                      vText.highPaintScaffoldSafety,
                      color: vTheme.colorScheme.error,
                    ),
                  IconLine(Icons.format_paint_outlined, vWallLine),
                  IconLine(Icons.roofing_outlined, vCeilingLine),
                  AddToShoppingButton(
                    items: () => [
                      if (vPlan.wallCans > 0)
                        ExtraItem(name: vText.highPaintWallPot, quantity: vPlan.wallCans),
                      if (vPlan.ceilingCans > 0)
                        ExtraItem(name: vText.highPaintCeilingPot, quantity: vPlan.ceilingCans),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.highPaintSteps, style: vTheme.textTheme.titleMedium),
          for (final (vIndex, vStep) in vSteps.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text('${vIndex + 1}')),
              title: Text(highStepLabel(vText, vStep)),
            ),
        ],
      ),
    );
  }
}
