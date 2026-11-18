import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import '../logic/wood_window.dart';
import 'glossary_view.dart';
import 'notebook.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Châssis fixe en bois pour remplacer un plexi : débit, assemblages, vitrage à commander.
class WoodWindowCalculator extends StatefulWidget {
  const WoodWindowCalculator({super.key});

  @override
  State<WoodWindowCalculator> createState() => _WoodWindowCalculatorState();
}

class _WoodWindowCalculatorState extends State<WoodWindowCalculator> {
  var _widthMm = 800;
  var _heightMm = 1000;
  var _frameWidthMm = 58;
  var _frameDepthMm = 70;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vW = _frameWidthMm;
    final vD = _frameDepthMm;
    final vWindow = planWoodWindow(
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pFrameWidthMm: _frameWidthMm,
      pFrameDepthMm: _frameDepthMm,
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.woodWindowTitle)),
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
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: WoodWindowSketch(window: vWindow, frameWidthMm: _frameWidthMm),
                  ),
                  const SizedBox(height: 8),
                  BigFigure(
                    vText.woodWindowGlass(vCm(vWindow.glassWidthMm), vCm(vWindow.glassHeightMm)),
                  ),
                  IconLine(
                    Icons.scale_outlined,
                    vText.woodWindowGlassWeight(formatDecimal(vWindow.glassKg.roundToDouble())),
                  ),
                  IconLine(
                    Icons.carpenter_outlined,
                    vText.woodWindowStiles(vCm(vWindow.stileLengthMm), vW, vD),
                  ),
                  IconLine(Icons.carpenter, vText.woodWindowRails(vCm(vWindow.railLengthMm))),
                  IconLine(
                    Icons.join_inner,
                    vText.woodWindowTenon(vWindow.tenonLengthMm, vWindow.tenonThicknessMm),
                  ),
                  IconLine(
                    Icons.straighten,
                    vText.woodWindowRebate(rebateDepthMm, vWindow.rebateWidthMm),
                  ),
                  IconLine(Icons.horizontal_rule, vText.woodWindowBead(vCm(vWindow.beadLengthMm))),
                  if (vWindow.frameTooThin)
                    IconLine(
                      Icons.warning_amber,
                      vText.woodWindowTooThin(minLipMm),
                      color: vTheme.colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
          const TermsRow([
            Term.frame,
            Term.stile,
            Term.rail,
            Term.tenon,
            Term.mortise,
            Term.rebate,
            Term.glazingBead,
            Term.setting,
          ]),
          WhyCard(
            title: vText.whyTitle,
            steps: [
              vText.woodWindowWhyOuter(
                fittingGapMm,
                vCm(vWindow.outerWidthMm),
                vCm(vWindow.outerHeightMm),
              ),
              vText.woodWindowWhyTenon(_frameDepthMm, _frameWidthMm),
              vText.woodWindowWhyGlass(rebateDepthMm, glassClearanceMm),
              vText.woodWindowWhyRebate(glassThicknessMm, glazingSealMm, beadThicknessMm),
            ],
          ),
          Text(vText.woodWindowSteps, style: vTheme.textTheme.bodySmall),
          NumberField(
            label: vText.woodWindowWidth,
            initial: vCm(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowHeight,
            initial: vCm(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowFrameWidth,
            initial: '$_frameWidthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _frameWidthMm = pValue),
          ),
          NumberField(
            label: vText.woodWindowFrameDepth,
            initial: '$_frameDepthMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _frameDepthMm = pValue),
          ),
        ],
      ),
    );
  }
}

/// Le châssis vu de face, à l'échelle : montants pleine hauteur, traverses entre eux,
/// tenons en pointillé, vitrage hachuré, cotes à la main.
class WoodWindowSketch extends StatelessWidget {
  const WoodWindowSketch({super.key, required this.window, required this.frameWidthMm});

  final WoodWindow window;
  final int frameWidthMm;

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);

    return CustomPaint(
      painter: _WindowPainter(
        window: window,
        frameWidthMm: frameWidthMm,
        ink: vColors.ink,
        wood: vColors.wood,
        style: TextStyle(fontFamily: handFont, fontSize: 18, color: vColors.ink),
      ),
    );
  }
}

class _WindowPainter extends CustomPainter {
  _WindowPainter({
    required this.window,
    required this.frameWidthMm,
    required this.ink,
    required this.wood,
    required this.style,
  });

  final WoodWindow window;
  final int frameWidthMm;
  final Color ink;
  final Color wood;
  final TextStyle style;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vWidth = window.outerWidthMm;
    final vHeight = window.outerHeightMm;
    if (vWidth <= 0 || vHeight <= 0) {
      return;
    }
    const vLeft = 46.0;
    const vBottom = 34.0;
    final vScaleX = (pSize.width - vLeft - 12) / vWidth;
    final vScale = math.min(vScaleX, (pSize.height - vBottom - 8) / vHeight);
    final vOuter = Rect.fromLTWH(vLeft, 8, vWidth * vScale, vHeight * vScale);
    final vBar = frameWidthMm * vScale;
    final vInner = vOuter.deflate(vBar);

    // Bois du cadre, puis vitrage hachuré
    pCanvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(vOuter), Path()..addRect(vInner)),
      Paint()..color = wood.withValues(alpha: 0.55),
    );
    final vHatch = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var vIndex = 0; vIndex < 3; vIndex++) {
      final vShift = Offset(vInner.width * (0.25 + vIndex * 0.12), vInner.height * 0.15);
      final vStart = vInner.topLeft + vShift;
      pCanvas.drawLine(vStart, vStart + Offset(vInner.width * 0.18, vInner.height * 0.18), vHatch);
    }

    final vPencil = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    void vRect(Rect pRect) {
      pencilLine(pCanvas, pRect.topLeft, pRect.topRight, vPencil);
      pencilLine(pCanvas, pRect.topRight, pRect.bottomRight, vPencil);
      pencilLine(pCanvas, pRect.bottomRight, pRect.bottomLeft, vPencil);
      pencilLine(pCanvas, pRect.bottomLeft, pRect.topLeft, vPencil);
    }

    vRect(vOuter);
    vRect(vInner);
    // Les montants vont de haut en bas : les traverses s'arrêtent contre eux
    for (final vX in [vInner.left, vInner.right]) {
      pencilLine(pCanvas, Offset(vX, vOuter.top), Offset(vX, vInner.top), vPencil);
      pencilLine(pCanvas, Offset(vX, vInner.bottom), Offset(vX, vOuter.bottom), vPencil);
    }
    // Tenons en pointillé, dans les montants
    final vDash = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    final vTenon = window.tenonLengthMm * vScale;
    for (final vX in [vInner.left - vTenon, vInner.right + vTenon]) {
      final vRails = [(vOuter.top + 4, vInner.top - 4), (vInner.bottom + 4, vOuter.bottom - 4)];
      for (final (vTop, vBottomY) in vRails) {
        for (var vY = vTop; vY < vBottomY; vY += 6) {
          pCanvas.drawLine(Offset(vX, vY), Offset(vX, math.min(vY + 3, vBottomY)), vDash);
        }
      }
    }

    final vMeasure = Paint()
      ..color = ink.withValues(alpha: 0.85)
      ..strokeWidth = 1;
    dimensionLine(
      pCanvas,
      vOuter.bottomLeft + const Offset(0, 16),
      vOuter.bottomRight + const Offset(0, 16),
      formatCentimetres(vWidth),
      vMeasure,
      style,
      pLabelShift: 12,
    );
    dimensionLine(
      pCanvas,
      vOuter.bottomLeft + const Offset(-18, 0),
      vOuter.topLeft + const Offset(-18, 0),
      formatCentimetres(vHeight),
      vMeasure,
      style,
      pLabelShift: -16,
    );
  }

  @override
  bool shouldRepaint(_WindowPainter pOld) =>
      pOld.window != window || pOld.frameWidthMm != frameWidthMm || pOld.ink != ink;
}
