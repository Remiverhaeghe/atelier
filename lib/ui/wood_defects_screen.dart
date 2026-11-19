import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import '../logic/wood_defects.dart';
import 'glossary_view.dart';
import 'parquet_view.dart';
import 'theme.dart';
import 'wood_defect_scenes.dart';

String defectName(AppLocalizations pText, WoodDefect pDefect) => switch (pDefect) {
  WoodDefect.knot => pText.defectKnot,
  WoodDefect.split => pText.defectSplit,
  WoodDefect.check => pText.defectCheck,
  WoodDefect.twist => pText.defectTwist,
  WoodDefect.bow => pText.defectBow,
  WoodDefect.cup => pText.defectCup,
  WoodDefect.moisture => pText.defectMoisture,
};

String _defectHelp(AppLocalizations pText, WoodDefect pDefect) => switch (pDefect) {
  WoodDefect.knot => pText.defectKnotHelp,
  WoodDefect.split => pText.defectSplitHelp,
  WoodDefect.check => pText.defectCheckHelp,
  WoodDefect.twist => pText.defectTwistHelp,
  WoodDefect.bow => pText.defectBowHelp,
  WoodDefect.cup => pText.defectCupHelp,
  WoodDefect.moisture => pText.defectMoistureHelp,
};

String _checkText(AppLocalizations pText, ShopCheck pCheck) => switch (pCheck) {
  ShopCheck.sight => pText.shopCheckSight,
  ShopCheck.flat => pText.shopCheckFlat,
  ShopCheck.ends => pText.shopCheckEnds,
  ShopCheck.knots => pText.shopCheckKnots,
  ShopCheck.edges => pText.shopCheckEdges,
  ShopCheck.moisture => pText.shopCheckMoisture,
  ShopCheck.grain => pText.shopCheckGrain,
  ShopCheck.spare => pText.shopCheckSpare,
};

String _useName(AppLocalizations pText, WoodUse pUse) => switch (pUse) {
  WoodUse.furniture => pText.woodUseFurniture,
  WoodUse.joinery => pText.woodUseJoinery,
  WoodUse.structure => pText.woodUseStructure,
};

/// Défauts du bois en relief, liste de contrôle au rayon et tri d'une planche mesurée.
class WoodDefectsScreen extends StatefulWidget {
  const WoodDefectsScreen({super.key});

  @override
  State<WoodDefectsScreen> createState() => _WoodDefectsScreenState();
}

class _WoodDefectsScreenState extends State<WoodDefectsScreen> {
  var _defect = WoodDefect.knot;
  final _done = <ShopCheck>{};
  var _use = WoodUse.furniture;
  var _lengthMm = 2400;
  var _widthMm = 120;
  var _bowMm = 0;
  var _twistMm = 0;
  var _cupMm = 0;
  var _knotMm = 0;
  var _looseKnot = false;
  var _splitMm = 0;
  var _moisture = 12;
  int? _neededMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vBoard = (
      lengthMm: _lengthMm,
      widthMm: _widthMm,
      bowMm: _bowMm,
      twistMm: _twistMm,
      cupMm: _cupMm,
      knotMm: _knotMm,
      looseKnot: _looseKnot,
      splitMm: _splitMm,
      moisturePercent: _moisture,
    );
    final vFindings = inspectBoard(vBoard, _use, pNeededMm: _neededMm);
    final vVerdict = boardVerdict(vFindings);
    Color? vColor(Verdict pVerdict) => switch (pVerdict) {
      Verdict.ok => null,
      Verdict.watch => vTheme.colorScheme.tertiary,
      Verdict.refuse => vTheme.colorScheme.error,
    };
    IconData vIcon(Verdict pVerdict) => switch (pVerdict) {
      Verdict.ok => Icons.check,
      Verdict.watch => Icons.visibility_outlined,
      Verdict.refuse => AtelierIcons.warning,
    };
    String vVerdictText(Verdict pVerdict) => switch (pVerdict) {
      Verdict.ok => vText.defectVerdictOk,
      Verdict.watch => vText.defectVerdictWatch,
      Verdict.refuse => vText.defectVerdictRefuse,
    };

    return Scaffold(
      appBar: AppBar(title: Text(vText.defectTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vDefect in WoodDefect.values)
                ChoiceChip(
                  label: Text(defectName(vText, vDefect)),
                  selected: _defect == vDefect,
                  onSelected: (_) => setState(() => _defect = vDefect),
                ),
            ],
          ),
          AspectRatio(aspectRatio: 1.5, child: WoodDefectSketch(defect: _defect)),
          Text(_defectHelp(vText, _defect)),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(vText.shopCheckTitle, style: vTheme.textTheme.titleMedium),
                  ),
                  for (final vCheck in ShopCheck.values)
                    CheckboxListTile(
                      dense: true,
                      value: _done.contains(vCheck),
                      title: Text(_checkText(vText, vCheck)),
                      onChanged: (pValue) => setState(
                        () => pValue == true ? _done.add(vCheck) : _done.remove(vCheck),
                      ),
                    ),
                  if (checklistDone(_done))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: IconLine(Icons.check_circle_outline, vText.shopCheckDone),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(vText.defectBoardTitle, style: vTheme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<WoodUse>(
            segments: [
              for (final vUse in WoodUse.values)
                ButtonSegment(value: vUse, label: Text(_useName(vText, vUse))),
            ],
            selected: {_use},
            onSelectionChanged: (pUses) => setState(() => _use = pUses.first),
          ),
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconLine(vIcon(vVerdict), vVerdictText(vVerdict), color: vColor(vVerdict)),
                  for (final vFinding in vFindings)
                    if (vFinding.verdict != Verdict.ok)
                      IconLine(
                        vIcon(vFinding.verdict),
                        vText.defectFinding(
                          defectName(vText, vFinding.defect),
                          vVerdictText(vFinding.verdict),
                        ),
                        color: vColor(vFinding.verdict),
                      ),
                  if (_splitMm > 0)
                    IconLine(
                      Icons.content_cut,
                      vText.defectUsable(formatCentimetres(usableLengthMm(vBoard))),
                    ),
                  Text(
                    vText.defectLimits(_use.moisture, _use.bowMm, _use.twistMm),
                    style: vTheme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          NumberField<int>(
            label: vText.defectLength,
            initial: formatCentimetres(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectWidth,
            initial: '$_widthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectBowField,
            initial: '$_bowMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _bowMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectTwistField,
            initial: '$_twistMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _twistMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectCupField,
            initial: '$_cupMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _cupMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectKnotField,
            initial: '$_knotMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _knotMm = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.defectLooseKnot),
            value: _looseKnot,
            onChanged: (pValue) => setState(() => _looseKnot = pValue),
          ),
          NumberField<int>(
            label: vText.defectSplitField,
            initial: formatCentimetres(_splitMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _splitMm = pValue),
          ),
          NumberField<int>(
            label: vText.defectMoistureField,
            initial: '$_moisture',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _moisture = pValue),
          ),
          NumberField<int>(
            label: vText.defectNeededField,
            initial: '',
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _neededMm = pValue == 0 ? null : pValue),
          ),
          const TermsRow([Term.grain, Term.edge]),
          Text(vText.defectHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
