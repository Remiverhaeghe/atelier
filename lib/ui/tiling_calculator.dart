import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/tiling.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Carrelage et faïence : calepinage dessiné, coupes de bord, quantités, colle et joint.
class TilingCalculator extends StatefulWidget {
  const TilingCalculator({super.key});

  @override
  State<TilingCalculator> createState() => _TilingCalculatorState();
}

class _TilingCalculatorState extends State<TilingCalculator> {
  var _design = const TilingDesign();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = tilingNeeds(_design);
    void vSet(TilingDesign pDesign) => setState(() => _design = pDesign);
    String vCuts(AxisLayout pAxis) => pAxis.startCutMm == 0 && pAxis.endCutMm == 0
        ? vText.tilingNoCut(pAxis.fullTiles)
        : pAxis.startCutMm == 0
        ? vText.tilingOneCut(pAxis.fullTiles, formatCentimetres(pAxis.endCutMm))
        : vText.tilingCuts(
            pAxis.fullTiles,
            formatCentimetres(pAxis.startCutMm),
            formatCentimetres(pAxis.endCutMm),
          );

    return Scaffold(
      appBar: AppBar(title: Text(vText.tilingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 220,
            child: CustomPaint(
              size: Size.infinite,
              painter: _TilingPainter(design: _design, needs: vNeeds, colors: AtelierColors.of(context)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigFigure(vText.tilingBoxes(vNeeds.boxes)),
                  IconLine(Icons.grid_on, vText.tilingTiles(vNeeds.tiles, formatDecimal(vNeeds.areaM2))),
                  IconLine(Icons.swap_horiz, vText.tilingAlongLength(vCuts(vNeeds.alongLength))),
                  IconLine(Icons.swap_vert, vText.tilingAlongWidth(vCuts(vNeeds.alongWidth))),
                  IconLine(Icons.format_color_fill, vText.tilingGlue(vNeeds.glueKg)),
                  IconLine(Icons.grain, vText.tilingJoint(formatDecimal(vNeeds.jointKg))),
                  IconLine(Icons.add, vText.tilingSpacers(vNeeds.spacers)),
                  const SizedBox(height: 4),
                  Text(vText.tilingHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.tilingCentered),
            subtitle: Text(vText.tilingCenteredHelp),
            value: _design.centered,
            onChanged: (pValue) => vSet(_design.copyWith(centered: pValue)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (vText.tilingLength, _design.lengthMm, (int pValue) => _design.copyWith(lengthMm: pValue)),
            (vText.tilingWidth, _design.widthMm, (int pValue) => _design.copyWith(widthMm: pValue)),
            (vText.tileLength, _design.tileLengthMm, (int pValue) => _design.copyWith(tileLengthMm: pValue)),
            (vText.tileWidth, _design.tileWidthMm, (int pValue) => _design.copyWith(tileWidthMm: pValue)),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          NumberField(
            label: vText.tilingJointWidth,
            initial: '${_design.jointMm}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(jointMm: pValue)),
          ),
          NumberField<double>(
            label: vText.tilingBoxArea,
            initial: formatDecimal(_design.boxM2),
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(boxM2: pValue)),
          ),
          NumberField(
            label: vText.wastePercent,
            initial: '${_design.marginPercent}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(marginPercent: pValue)),
          ),
        ],
      ),
    );
  }
}

/// Carreaux entiers en clair, coupes de bord en plus foncé, comme sur un calepinage papier.
class _TilingPainter extends CustomPainter {
  _TilingPainter({required this.design, required this.needs, required this.colors});

  final TilingDesign design;
  final TilingNeeds needs;
  final AtelierColors colors;

  List<int> _sizes(AxisLayout pAxis, int pTile) => [
    if (pAxis.startCutMm > 0) pAxis.startCutMm,
    for (var vIndex = 0; vIndex < pAxis.fullTiles; vIndex++) pTile,
    if (pAxis.endCutMm > 0) pAxis.endCutMm,
  ];

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (design.lengthMm <= 0 || design.widthMm <= 0) {
      return;
    }
    final vScale = [pSize.width / design.lengthMm, pSize.height / design.widthMm].reduce(
      (pA, pB) => pA < pB ? pA : pB,
    );
    final vLeft = (pSize.width - design.lengthMm * vScale) / 2;
    final vTop = (pSize.height - design.widthMm * vScale) / 2;
    final vColumns = _sizes(needs.alongLength, design.tileLengthMm);
    final vRows = _sizes(needs.alongWidth, design.tileWidthMm);
    final vJoint = design.jointMm * vScale;
    var vY = vTop;
    for (var vRow = 0; vRow < vRows.length; vRow++) {
      var vX = vLeft;
      for (var vColumn = 0; vColumn < vColumns.length; vColumn++) {
        final vCut = vColumns[vColumn] != design.tileLengthMm || vRows[vRow] != design.tileWidthMm;
        pCanvas.drawRect(
          Rect.fromLTWH(vX, vY, vColumns[vColumn] * vScale, vRows[vRow] * vScale),
          Paint()..color = vCut ? colors.tape.withValues(alpha: 0.55) : colors.grid,
        );
        vX += vColumns[vColumn] * vScale + vJoint;
      }
      vY += vRows[vRow] * vScale + vJoint;
    }
    pCanvas.drawRect(
      Rect.fromLTWH(vLeft, vTop, design.lengthMm * vScale, design.widthMm * vScale),
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_TilingPainter pOld) => pOld.design != design;
}
