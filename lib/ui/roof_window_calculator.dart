import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/roof_window.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import 'glossary_view.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Remplacer un plexi du toit par une fenêtre de toit : largeur, chevêtre, hauteur, pose.
class RoofWindowCalculator extends StatefulWidget {
  const RoofWindowCalculator({super.key});

  @override
  State<RoofWindowCalculator> createState() => _RoofWindowCalculatorState();
}

class _RoofWindowCalculatorState extends State<RoofWindowCalculator> {
  var _spacingMm = 600;
  var _rafterMm = 63;
  var _wantedMm = 550;
  var _slopeDeg = 40;
  var _cover = RoofCover.profiledTiles;
  String _reference = '';

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vFit = fitRoofWindow(
      pSpacingMm: _spacingMm,
      pRafterWidthMm: _rafterMm,
      pWantedWidthMm: _wantedMm,
      pSlopeDeg: _slopeDeg.toDouble(),
    );
    final vChosen = vFit.chosenWidthMm;
    final vKnown = roofWindowFromReference(_reference);
    final vWithout = vFit.widestWithoutCutMm;

    return Scaffold(
      appBar: AppBar(title: Text(vText.roofWindowTitle)),
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
                  if (vChosen == null)
                    IconLine(
                      Icons.warning_amber,
                      vText.roofWindowNone,
                      color: vTheme.colorScheme.error,
                    )
                  else
                    BigFigure(vText.roofWindowChosen(vCm(vChosen), vCm(vFit.heightMm))),
                  IconLine(
                    Icons.view_week_outlined,
                    vWithout == null
                        ? vText.roofWindowClearNone(vCm(vFit.clearWidthMm))
                        : vText.roofWindowClear(vCm(vFit.clearWidthMm), vCm(vWithout)),
                  ),
                  if (vFit.needsHeader)
                    IconLine(
                      Icons.content_cut,
                      vText.roofWindowHeader,
                      color: vTheme.colorScheme.error,
                    ),
                  IconLine(
                    Icons.roofing,
                    _cover == RoofCover.profiledTiles
                        ? vText.roofWindowFlashingProfiled
                        : vText.roofWindowFlashingFlat,
                  ),
                  Text(vText.roofWindowSteps, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const TermsRow([Term.rafter, Term.spacing, Term.header]),
          NumberField<String>(
            label: vText.roofWindowReference,
            initial: '',
            parse: (pText) => pText,
            onValue: (pValue) => setState(() {
              _reference = pValue;
              final vSize = roofWindowFromReference(pValue);
              if (vSize != null) {
                _wantedMm = vSize.widthMm;
              }
            }),
          ),
          if (_reference.trim().isNotEmpty)
            IconLine(
              vKnown == null ? Icons.help_outline : Icons.check_circle_outline,
              vKnown == null
                  ? vText.roofWindowReferenceUnknown
                  : vText.roofWindowReferenceSize(vCm(vKnown.widthMm), vCm(vKnown.heightMm)),
            ),
          const SizedBox(height: 12),
          SegmentedButton<RoofCover>(
            segments: [
              ButtonSegment(value: RoofCover.profiledTiles, label: Text(vText.roofCoverProfiled)),
              ButtonSegment(value: RoofCover.flat, label: Text(vText.roofCoverFlat)),
            ],
            selected: {_cover},
            onSelectionChanged: (pSelection) => setState(() => _cover = pSelection.first),
          ),
          NumberField(
            label: vText.roofWindowSpacing,
            initial: vCm(_spacingMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _spacingMm = pValue),
          ),
          NumberField(
            label: vText.roofWindowRafter,
            initial: '$_rafterMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _rafterMm = pValue),
          ),
          NumberField(
            // Recréé quand une référence reconnue impose la largeur
            key: ValueKey('wanted-${vKnown?.code}'),
            label: vText.roofWindowWanted,
            initial: vCm(_wantedMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _wantedMm = pValue),
          ),
          NumberField(
            label: vText.slopeAngle,
            initial: '$_slopeDeg',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _slopeDeg = pValue),
          ),
        ],
      ),
    );
  }
}
