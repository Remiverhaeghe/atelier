import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/niche_shelf.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Étagères dans une niche sur tasseaux, ou meuble sous un rampant de combles.
class NicheShelfCalculator extends StatefulWidget {
  const NicheShelfCalculator({super.key});

  @override
  State<NicheShelfCalculator> createState() => _NicheShelfCalculatorState();
}

class _NicheShelfCalculatorState extends State<NicheShelfCalculator> {
  var _underSlope = false;
  var _widthMm = 800;
  var _depthMm = 300;
  var _shelves = 4;
  var _kneeWallMm = 800;
  var _slopeDeg = 45;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vNiche = planNiche(_widthMm, _depthMm, _shelves);
    final vSlope = planUnderSlope(_kneeWallMm, _slopeDeg.toDouble(), _depthMm, _shelves);

    return Scaffold(
      appBar: AppBar(title: Text(vText.nicheTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(vText.nicheModeNiche)),
              ButtonSegment(value: true, label: Text(vText.nicheModeSlope)),
            ],
            selected: {_underSlope},
            onSelectionChanged: (pSelection) => setState(() => _underSlope = pSelection.first),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _underSlope
                    ? [
                        IconLine(
                          Icons.change_history,
                          vText.slopeSides(
                            vCm(vSlope.sideBackMm),
                            vCm(vSlope.sideFrontMm),
                            _slopeDeg,
                          ),
                        ),
                        for (final vShelf in vSlope.shelves)
                          IconLine(
                            Icons.horizontal_rule,
                            vText.slopeShelf(vCm(vShelf.heightMm), vCm(vShelf.depthMm)),
                          ),
                        Text(vText.slopeHint, style: Theme.of(context).textTheme.bodySmall),
                      ]
                    : [
                        BigFigure(vText.nicheShelves(_shelves, vCm(vNiche.shelfLengthMm))),
                        IconLine(
                          Icons.view_week_outlined,
                          vText.nicheCleats(
                            vNiche.cleats,
                            vCm(vNiche.backCleatMm),
                            vCm(vNiche.sideCleatMm),
                          ),
                        ),
                        IconLine(Icons.hardware_outlined, vText.nicheScrews(vNiche.screws)),
                        Text(vText.nicheHint, style: Theme.of(context).textTheme.bodySmall),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_underSlope) ...[
            NumberField(
              label: vText.slopeKneeWall,
              initial: vCm(_kneeWallMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _kneeWallMm = pValue),
            ),
            NumberField(
              label: vText.slopeAngle,
              initial: '$_slopeDeg',
              parse: parseWhole,
              onValue: (pValue) => setState(() => _slopeDeg = pValue),
            ),
          ] else
            NumberField(
              label: vText.shelfWidth,
              initial: vCm(_widthMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _widthMm = pValue),
            ),
          NumberField(
            label: vText.shelfDepth,
            initial: vCm(_depthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _depthMm = pValue),
          ),
          NumberField(
            label: vText.nicheCount,
            initial: '$_shelves',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _shelves = pValue),
          ),
        ],
      ),
    );
  }
}
