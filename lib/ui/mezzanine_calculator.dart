import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mezzanine.dart';
import '../logic/mezzanine_floor.dart';
import '../logic/units.dart';
import 'mezzanine_floor_card.dart';
import 'parquet_view.dart';
import 'theme.dart';

String mezzanineUseLabel(AppLocalizations pText, MezzanineUse pUse) => switch (pUse) {
  MezzanineUse.living => pText.mezzanineUseLiving,
  MezzanineUse.storage => pText.mezzanineUseStorage,
};

String mezzanineSupportLabel(AppLocalizations pText, MezzanineSupport pSupport) =>
    switch (pSupport) {
      MezzanineSupport.oneWall => pText.mezzanineOneWall,
      MezzanineSupport.twoWalls => pText.mezzanineTwoWalls,
      MezzanineSupport.freestanding => pText.mezzanineFreestanding,
    };

/// Mezzanine : structure, plancher et garde-corps.
class MezzanineCalculator extends StatefulWidget {
  const MezzanineCalculator({super.key});

  @override
  State<MezzanineCalculator> createState() => _MezzanineCalculatorState();
}

class _MezzanineCalculatorState extends State<MezzanineCalculator> {
  var _mezzanine = const Mezzanine();
  var _panel = FloorPanel.osb3;
  var _stairOpeningMm = 700;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planMezzanine(_mezzanine);
    final vJoist = vPlan.joist;
    final vBeam = vPlan.beam;
    final vPostSide = vPlan.postSideMm;
    void vSet(Mezzanine pMezzanine) => setState(() => _mezzanine = pMezzanine);

    return Scaffold(
      appBar: AppBar(title: Text(vText.mezzanineTitle)),
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
                  Text(vText.mezzanineStructure, style: vTheme.textTheme.titleMedium),
                  if (vJoist == null)
                    IconLine(
                      Icons.warning_amber,
                      vText.mezzanineJoistTooLong,
                      color: vTheme.colorScheme.error,
                    )
                  else
                    IconLine(
                      Icons.view_week_outlined,
                      vText.mezzanineJoists(
                        vPlan.joists,
                        vJoist.widthMm,
                        vJoist.heightMm,
                        formatCentimetres(_mezzanine.joistSpacingMm),
                      ),
                    ),
                  if (vPlan.ledgers > 0)
                    IconLine(
                      Icons.horizontal_rule,
                      vText.mezzanineLedgers(vPlan.ledgers, vPlan.anchorsPerLedger),
                    ),
                  if (vPlan.beams > 0)
                    if (vBeam == null)
                      IconLine(
                        Icons.warning_amber,
                        vText.mezzanineBeamTooLong,
                        color: vTheme.colorScheme.error,
                      )
                    else
                      IconLine(
                        Icons.straighten,
                        vText.mezzanineBeams(vPlan.beams, vBeam.widthMm, vBeam.heightMm),
                      ),
                  if (vPlan.beams > 0)
                    IconLine(
                      Icons.vertical_align_bottom,
                      vPostSide == null
                          ? vText.mezzaninePostTooSlender
                          : vText.mezzaninePosts(
                              vPlan.postsPerBeam * vPlan.beams,
                              vPostSide,
                              formatCentimetres(vPlan.postSpacingMm),
                              vPlan.postLoadKn.round(),
                            ),
                      color: vPostSide == null ? vTheme.colorScheme.error : null,
                    ),
                  IconLine(Icons.hardware_outlined, vText.mezzanineHangers(vPlan.hangers)),
                  if (vPlan.beams > 0) IconLine(Icons.change_history, vText.mezzanineBracing),
                  Text(vText.mezzanineWarning, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MezzanineFloorCard(mezzanine: _mezzanine, panel: _panel, stairOpeningMm: _stairOpeningMm),
          const SizedBox(height: 12),
          DropdownButtonFormField<MezzanineSupport>(
            initialValue: _mezzanine.support,
            decoration: InputDecoration(labelText: vText.mezzanineSupport),
            items: [
              for (final vSupport in MezzanineSupport.values)
                DropdownMenuItem(
                  value: vSupport,
                  child: Text(mezzanineSupportLabel(vText, vSupport)),
                ),
            ],
            onChanged: (pSupport) => vSet(_mezzanine.copyWith(support: pSupport)),
          ),
          DropdownButtonFormField<MezzanineUse>(
            initialValue: _mezzanine.use,
            decoration: InputDecoration(labelText: vText.mezzanineUse),
            items: [
              for (final vUse in MezzanineUse.values)
                DropdownMenuItem(value: vUse, child: Text(mezzanineUseLabel(vText, vUse))),
            ],
            onChanged: (pUse) => vSet(_mezzanine.copyWith(use: pUse)),
          ),
          DropdownButtonFormField<int>(
            initialValue: _mezzanine.joistSpacingMm,
            decoration: InputDecoration(labelText: vText.mezzanineSpacing),
            items: [
              for (final vSpacing in const [400, 500, 600])
                DropdownMenuItem(value: vSpacing, child: Text(formatCentimetres(vSpacing))),
            ],
            onChanged: (pSpacing) => vSet(_mezzanine.copyWith(joistSpacingMm: pSpacing)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (
              vText.mezzanineLength,
              _mezzanine.lengthMm,
              (int pValue) => _mezzanine.copyWith(lengthMm: pValue),
            ),
            (
              vText.mezzanineDepth,
              _mezzanine.depthMm,
              (int pValue) => _mezzanine.copyWith(depthMm: pValue),
            ),
            (
              vText.mezzaninePostHeight,
              _mezzanine.postHeightMm,
              (int pValue) => _mezzanine.copyWith(postHeightMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          DropdownButtonFormField<FloorPanel>(
            initialValue: _panel,
            decoration: InputDecoration(labelText: vText.floorPanel),
            items: [
              for (final vPanel in FloorPanel.values)
                DropdownMenuItem(value: vPanel, child: Text(floorPanelLabel(vText, vPanel))),
            ],
            onChanged: (pPanel) => setState(() => _panel = pPanel ?? _panel),
          ),
          NumberField(
            label: vText.guardrailStairOpening,
            initial: formatCentimetres(_stairOpeningMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _stairOpeningMm = pValue),
          ),
        ],
      ),
    );
  }
}
