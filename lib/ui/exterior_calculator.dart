import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/exterior.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Façade à peindre ou enduire, et clôture en panneaux rigides.
class ExteriorCalculator extends StatefulWidget {
  const ExteriorCalculator({super.key});

  @override
  State<ExteriorCalculator> createState() => _ExteriorCalculatorState();
}

class _ExteriorCalculatorState extends State<ExteriorCalculator> {
  bool _fence = false;
  int _width = 8000;
  int _height = 5500;
  int _gable = 0;
  double _openings = 6;
  int _length = 25000;
  int _sides = 1;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    NumberField<int> vField(String pLabel, int pInitial, ValueChanged<int> pSet) =>
        NumberField<int>(
          // Clé par champ : sans elle, passer de la façade à la clôture garderait les saisies
          key: ValueKey(pLabel),
          label: pLabel,
          initial: '$pInitial',
          parse: parseWhole,
          onValue: (pValue) => setState(() => pSet(pValue)),
        );
    final vArea = facadeM2((
      widthMm: _width,
      heightMm: _height,
      gableMm: _gable,
      openingsM2: _openings,
    ));
    final vFence = fencePlan(_length, pSides: _sides);

    return Scaffold(
      appBar: AppBar(title: Text(vText.exteriorTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(vText.exteriorFacade)),
              ButtonSegment(value: true, label: Text(vText.exteriorFence)),
            ],
            selected: {_fence},
            onSelectionChanged: (pValue) => setState(() => _fence = pValue.single),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _fence
                    ? [
                        BigFigure(vText.fencePanels(vFence.panels)),
                        IconLine(Icons.fence, vText.fencePosts(vFence.posts)),
                        IconLine(
                          Icons.inventory_2_outlined,
                          vText.fenceConcrete(vFence.concreteBags),
                        ),
                        if (vFence.lastPanelMm < fencePanelMm)
                          IconLine(
                            Icons.content_cut,
                            vText.fenceLast(formatCentimetres(vFence.lastPanelMm)),
                          ),
                      ]
                    : [
                        BigFigure('${formatSquareMetres(vArea)} m²'),
                        IconLine(
                          Icons.format_paint_outlined,
                          vText.facadePaint(formatDecimal(facadePaintLitres(vArea))),
                        ),
                        IconLine(Icons.layers_outlined, vText.facadeRender(renderBags(vArea))),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_fence) ...[
            vField(vText.fenceLength, _length, (pValue) => _length = pValue),
            vField(vText.fenceSides, _sides, (pValue) => _sides = pValue),
            Text(vText.fenceHint, style: vTheme.textTheme.bodySmall),
          ] else ...[
            vField(vText.facadeWidth, _width, (pValue) => _width = pValue),
            vField(vText.facadeHeight, _height, (pValue) => _height = pValue),
            vField(vText.facadeGable, _gable, (pValue) => _gable = pValue),
            NumberField<double>(
              label: vText.facadeOpenings,
              initial: formatDecimal(_openings),
              parse: parseDecimal,
              onValue: (pValue) => setState(() => _openings = pValue),
            ),
            Text(vText.facadeHint, style: vTheme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
