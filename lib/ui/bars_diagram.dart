import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/bar_cutting.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Les barres de plinthe à l'échelle : chaque barre est un rectangle, ses morceaux y sont
/// dessinés dans l'ordre de la coupe avec leur longueur, les traits de scie entre eux, et la
/// chute en grisé, comme les lames du parquet sur le plan de pose.
class BarsDiagram extends StatelessWidget {
  const BarsDiagram({super.key, required this.plan});

  final BarPlan plan;

  /// Hauteur d'une barre dessinée.
  static const barHeight = 28.0;
  static const gap = 8.0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    if (plan.bars.isEmpty) {
      return const SizedBox.shrink();
    }
    final vHeight = plan.bars.length * (barHeight + gap);

    return Semantics(
      label: vText.barsDiagramLabel,
      child: SizedBox(
        height: vHeight,
        child: CustomPaint(
          size: Size.infinite,
          painter: BarsPainter(
            plan: plan,
            colors: AtelierColors.of(context),
            line: vTheme.colorScheme.onSurface,
            label: vTheme.textTheme.labelSmall!.copyWith(color: vTheme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class BarsPainter extends CustomPainter {
  BarsPainter({required this.plan, required this.colors, required this.line, required this.label});

  final BarPlan plan;
  final AtelierColors colors;
  final Color line;
  final TextStyle label;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vBarMm = plan.bars.map((pBar) => pBar.barMm).reduce((pA, pB) => pA > pB ? pA : pB);
    final vScale = pSize.width / vBarMm;
    final vWood = Paint()..color = colors.woodLaid;
    final vOffcut = Paint()..color = line.withValues(alpha: 0.12);
    final vOutline = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final vSaw = Paint()
      ..color = line
      ..strokeWidth = 1.5;

    for (var vBar = 0; vBar < plan.bars.length; vBar++) {
      final vTop = vBar * (BarsDiagram.barHeight + BarsDiagram.gap);
      final vCut = plan.bars[vBar];
      var vX = 0.0;

      for (var vPiece = 0; vPiece < vCut.pieceLengths.length; vPiece++) {
        final vWidth = vCut.pieceLengths[vPiece] * vScale;
        final vRect = Rect.fromLTWH(vX, vTop, vWidth, BarsDiagram.barHeight);
        pCanvas
          ..drawRect(vRect, vWood)
          ..drawRect(vRect, vOutline);
        _text(pCanvas, formatCentimetres(vCut.pieceLengths[vPiece]), vRect);
        vX += vWidth;
        // Trait de scie entre deux morceaux, dessiné à son épaisseur réelle au moins 1,5 point
        pCanvas.drawLine(Offset(vX, vTop), Offset(vX, vTop + BarsDiagram.barHeight), vSaw);
        vX += plan.kerfMm * vScale;
      }
      final vRest = Rect.fromLTRB(vX, vTop, vCut.barMm * vScale, vTop + BarsDiagram.barHeight);
      if (vRest.width > 0) {
        pCanvas
          ..drawRect(vRest, vOffcut)
          ..drawRect(vRest, vOutline);
        if (vCut.offcutMm(plan.kerfMm) >= reusableOffcutMm) {
          _text(pCanvas, formatCentimetres(vCut.offcutMm(plan.kerfMm)), vRest);
        }
      }
    }
  }

  void _text(Canvas pCanvas, String pText, Rect pRect) {
    final vPainter = TextPainter(
      text: TextSpan(text: pText, style: label),
      textDirection: TextDirection.ltr,
    )..layout();
    if (vPainter.width + 4 <= pRect.width) {
      vPainter.paint(
        pCanvas,
        Offset(pRect.left + (pRect.width - vPainter.width) / 2, pRect.center.dy - vPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(BarsPainter pOld) =>
      pOld.plan != plan || pOld.colors != colors || pOld.line != line;
}
