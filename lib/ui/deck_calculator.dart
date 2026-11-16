import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/deck.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Terrasse bois : dessin vu de dessus, lames, lambourdes, plots et vis.
class DeckCalculator extends StatefulWidget {
  const DeckCalculator({super.key});

  @override
  State<DeckCalculator> createState() => _DeckCalculatorState();
}

class _DeckCalculatorState extends State<DeckCalculator> {
  var _design = const DeckDesign();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = deckNeeds(_design);
    void vSet(DeckDesign pDesign) => setState(() => _design = pDesign);

    return Scaffold(
      appBar: AppBar(title: Text(vText.deckTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DeckPainter(
                design: _design,
                needs: vNeeds,
                colors: AtelierColors.of(context),
              ),
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
                  BigFigure(vText.deckBoards(vNeeds.boards)),
                  IconLine(Icons.crop_free, vText.totalArea(formatDecimal(vNeeds.areaM2))),
                  IconLine(
                    Icons.view_week_outlined,
                    vText.deckJoists(
                      vNeeds.joists,
                      formatCentimetres(vNeeds.joistSpacingMm),
                      vNeeds.joistBars,
                    ),
                  ),
                  IconLine(Icons.adjust, vText.deckPlots(vNeeds.plots)),
                  IconLine(Icons.hardware_outlined, vText.deckScrews(vNeeds.screws)),
                  const SizedBox(height: 4),
                  Text(vText.deckHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final (vLabel, vValue, vApply) in [
            (
              vText.deckLength,
              _design.lengthMm,
              (int pValue) => _design.copyWith(lengthMm: pValue),
            ),
            (vText.deckWidth, _design.widthMm, (int pValue) => _design.copyWith(widthMm: pValue)),
            (
              vText.deckBoardWidth,
              _design.boardWidthMm,
              (int pValue) => _design.copyWith(boardWidthMm: pValue),
            ),
            (
              vText.deckBoardThickness,
              _design.boardThicknessMm,
              (int pValue) => _design.copyWith(boardThicknessMm: pValue),
            ),
            (
              vText.deckBoardLength,
              _design.boardLengthMm,
              (int pValue) => _design.copyWith(boardLengthMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          NumberField(
            label: vText.deckGap,
            initial: '${_design.gapMm}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(gapMm: pValue)),
          ),
        ],
      ),
    );
  }
}

/// Lames dans la longueur, lambourdes en pointillé dessous, plots aux croisements.
class _DeckPainter extends CustomPainter {
  _DeckPainter({required this.design, required this.needs, required this.colors});

  final DeckDesign design;
  final DeckNeeds needs;
  final AtelierColors colors;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (needs.rows == 0) {
      return;
    }
    final vScale = [
      pSize.width / design.lengthMm,
      pSize.height / design.widthMm,
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vWidth = design.lengthMm * vScale;
    final vHeight = design.widthMm * vScale;
    final vLeft = (pSize.width - vWidth) / 2;
    final vTop = (pSize.height - vHeight) / 2;
    final vJoist = Paint()
      ..color = colors.ink.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var vIndex = 0; vIndex < needs.joists; vIndex++) {
      final vX = vLeft + (vIndex * needs.joistSpacingMm * vScale).clamp(0.0, vWidth);
      pCanvas.drawLine(Offset(vX, vTop), Offset(vX, vTop + vHeight), vJoist);
    }
    final vRowHeight = vHeight / needs.rows;
    final vBoard = Paint()..color = colors.woodLaid;
    for (var vRow = 0; vRow < needs.rows; vRow++) {
      // Joints décalés d'une rangée à l'autre, comme à la pose
      final vY = vTop + vRow * vRowHeight;
      pCanvas.drawRect(Rect.fromLTWH(vLeft, vY + 0.5, vWidth, vRowHeight - 1.5), vBoard);
      final vOffset = (vRow.isEven ? 0 : design.boardLengthMm / 2) * vScale;
      for (var vX = vLeft + vOffset; vX < vLeft + vWidth; vX += design.boardLengthMm * vScale) {
        if (vX > vLeft) {
          pCanvas.drawLine(
            Offset(vX, vY),
            Offset(vX, vY + vRowHeight),
            Paint()..color = colors.ink,
          );
        }
      }
    }
    pCanvas.drawRect(
      Rect.fromLTWH(vLeft, vTop, vWidth, vHeight),
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DeckPainter pOld) => pOld.design != design;
}
