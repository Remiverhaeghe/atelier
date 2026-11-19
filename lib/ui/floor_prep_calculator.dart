import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/floor_prep.dart';
import '../logic/screed.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'screed_calculator.dart';
import 'theme.dart';

String screedKindLabel(AppLocalizations pText, ScreedKind pKind) => switch (pKind) {
  ScreedKind.dry => pText.screedKindDry,
  ScreedKind.liquidAnhydrite => pText.screedKindLiquid,
  ScreedKind.cement => pText.screedKindCement,
};

/// Préparer un sol : chape, sous-couche, joints de dilatation et séchage avant la pose.
class FloorPrepCalculator extends StatefulWidget {
  const FloorPrepCalculator({super.key});

  @override
  State<FloorPrepCalculator> createState() => _FloorPrepCalculatorState();
}

class _FloorPrepCalculatorState extends State<FloorPrepCalculator> {
  var _kind = ScreedKind.cement;
  var _covering = Covering.floating;
  var _length = 5000;
  var _width = 4000;
  var _thickness = 50;
  double? _moisture;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vArea = _length * _width / 1e6;
    final vOrder = screedOrder(_kind, vArea, _thickness);
    final vDays = screedKindDryingDays(_kind, _thickness);
    final vRolls = underlayRolls(_covering, vArea);
    final vJoints = expansionJoints(_covering, _length, _width);
    final vMoisture = _moisture;

    return Scaffold(
      appBar: AppBar(title: Text(vText.floorPrepTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.floorPrepIntro, style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(vText.floorPrepScreed, style: vTheme.textTheme.titleSmall),
          SegmentedButton<ScreedKind>(
            segments: [
              for (final vKind in ScreedKind.values)
                ButtonSegment(value: vKind, label: Text(screedKindLabel(vText, vKind))),
            ],
            selected: {_kind},
            onSelectionChanged: (pChoice) => setState(() => _kind = pChoice.single),
          ),
          DropdownButtonFormField<Covering>(
            initialValue: _covering,
            decoration: InputDecoration(labelText: vText.floorPrepCovering),
            items: [
              for (final vCovering in Covering.values)
                DropdownMenuItem(value: vCovering, child: Text(coveringLabel(vText, vCovering))),
            ],
            onChanged: (pCovering) => setState(() => _covering = pCovering!),
          ),
          NumberField<int>(
            label: vText.floorPrepLength,
            initial: formatCentimetres(_length),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _length = pValue),
          ),
          NumberField<int>(
            label: vText.floorPrepWidth,
            initial: formatCentimetres(_width),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _width = pValue),
          ),
          NumberField<int>(
            label: vText.floorPrepThickness,
            initial: '$_thickness',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _thickness = pValue),
          ),
          NumberField<double>(
            label: vText.floorPrepMoisture,
            initial: '',
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _moisture = pValue),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.floorPrepArea(formatDecimal(vArea))),
                  if (_thickness < _kind.minThicknessMm)
                    IconLine(
                      AtelierIcons.warning,
                      vText.floorPrepThin(_kind.minThicknessMm),
                      color: vTheme.colorScheme.error,
                    ),
                  IconLine(Icons.layers_outlined, switch (_kind) {
                    ScreedKind.dry => vText.floorPrepBoards(vOrder.boards, vOrder.grainBags),
                    ScreedKind.cement => vText.floorPrepCementBags(vOrder.cementBags),
                    ScreedKind.liquidAnhydrite => vText.floorPrepVolume(
                      formatDecimal(vOrder.volumeM3),
                    ),
                  }),
                  IconLine(
                    Icons.hourglass_bottom,
                    vDays == 0 ? vText.floorPrepNoDrying : vText.floorPrepDrying(vDays),
                  ),
                  if (_kind != ScreedKind.dry)
                    IconLine(
                      Icons.water_drop_outlined,
                      vText.floorPrepMoistureTarget(formatDecimal(_kind.maxMoisturePercent)),
                    ),
                  if (vMoisture != null)
                    IconLine(
                      readyToLay(_kind, vMoisture) ? Icons.check : AtelierIcons.warning,
                      readyToLay(_kind, vMoisture)
                          ? vText.floorPrepReady
                          : vText.floorPrepNotReady,
                    ),
                  IconLine(Icons.texture, switch (underlayFor(_covering)) {
                    Underlay.none => vText.floorPrepUnderlayNone,
                    Underlay.foamWithFilm => vText.floorPrepUnderlayFoam(vRolls),
                    Underlay.thinDense => vText.floorPrepUnderlayThin(vRolls),
                  }),
                  IconLine(Icons.border_outer, vText.floorPrepGap(perimeterGapMm(_covering))),
                  if (vJoints.doorThresholds)
                    IconLine(Icons.door_front_door_outlined, vText.floorPrepThresholds),
                  if (vJoints.extraJoints > 0)
                    IconLine(Icons.splitscreen, vText.floorPrepSplits(vJoints.extraJoints)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(vText.floorPrepRagreage, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
