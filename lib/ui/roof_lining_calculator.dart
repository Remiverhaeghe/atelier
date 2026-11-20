import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/roof_lining.dart';
import '../logic/glossary.dart';
import '../logic/units.dart';
import 'glossary_view.dart';
import 'notebook.dart';
import 'parquet_view.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';

/// Embrasure d'une fenêtre de toit : haut horizontal, bas vertical, pour la lumière.
class RoofLiningCalculator extends StatefulWidget {
  const RoofLiningCalculator({super.key});

  @override
  State<RoofLiningCalculator> createState() => _RoofLiningCalculatorState();
}

class _RoofLiningCalculatorState extends State<RoofLiningCalculator> {
  var _widthMm = 780;
  var _heightMm = 980;
  var _depthMm = 220;
  var _slopeDeg = 40;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vLining = planRoofLining(
      pWindowWidthMm: _widthMm,
      pWindowHeightMm: _heightMm,
      pDepthMm: _depthMm,
      pSlopeDeg: _slopeDeg.toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.liningTitle),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: vText.liningTitle,
              intro: vText.liningHelp,
              measures: [
                (vText.liningWindowWidth, vCm(_widthMm)),
                (vText.liningWindowHeight, vCm(_heightMm)),
                (vText.liningDepth, vCm(_depthMm)),
                (vText.slopeAngle, '$_slopeDeg'),
              ],
              results: [
                vText.liningOpening(vCm(vLining.ceilingOpeningMm)),
                vText.liningGain(vCm(vLining.gainMm)),
                vText.liningTop(vCm(vLining.topMm)),
                vText.liningBottom(vCm(vLining.bottomMm)),
              ],
              buy: const [],
              steps: [
                vText.liningWhyTop(vCm(_depthMm), _slopeDeg),
                vText.liningWhyBottom(_slopeDeg),
                vText.liningWhyOpening(vCm(_heightMm), vCm(vLining.gainMm)),
              ],
            ),
          ),
        ],
      ),
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
                    aspectRatio: 1.4,
                    child: RoofLiningSketch(
                      lining: vLining,
                      windowHeightMm: _heightMm,
                      depthMm: _depthMm,
                      slopeDeg: _slopeDeg.toDouble(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BigFigure(vText.liningOpening(vCm(vLining.ceilingOpeningMm))),
                  IconLine(Icons.wb_sunny_outlined, vText.liningGain(vCm(vLining.gainMm))),
                  IconLine(Icons.horizontal_rule, vText.liningTop(vCm(vLining.topMm))),
                  IconLine(Icons.vertical_align_bottom, vText.liningBottom(vCm(vLining.bottomMm))),
                  IconLine(
                    Icons.layers_outlined,
                    vText.liningBoard(formatDecimal((vLining.boardM2 * 100).round() / 100)),
                  ),
                ],
              ),
            ),
          ),
          const TermsRow([Term.reveal, Term.slope, Term.rafter, Term.header, Term.plasterboard]),
          WhyCard(
            title: vText.whyTitle,
            steps: [
              vText.liningWhyTop(vCm(_depthMm), _slopeDeg),
              vText.liningWhyBottom(_slopeDeg),
              vText.liningWhyOpening(vCm(_heightMm), vCm(vLining.gainMm)),
            ],
          ),
          Text(vText.liningSteps, style: vTheme.textTheme.bodySmall),
          NumberField(
            label: vText.liningWindowWidth,
            initial: vCm(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.liningWindowHeight,
            initial: vCm(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
          NumberField(
            label: vText.liningDepth,
            initial: vCm(_depthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _depthMm = pValue),
          ),
          NumberField(
            label: vText.slopeAngle,
            initial: '$_slopeDeg',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _slopeDeg = pValue.clamp(5, 85)),
          ),
        ],
      ),
    );
  }
}

/// Coupe de l'embrasure : rampant, fenêtre, haut horizontal et bas vertical, lumière qui entre.
class RoofLiningSketch extends StatelessWidget {
  const RoofLiningSketch({
    super.key,
    required this.lining,
    required this.windowHeightMm,
    required this.depthMm,
    required this.slopeDeg,
  });

  final RoofLining lining;
  final int windowHeightMm;
  final int depthMm;
  final double slopeDeg;

  @override
  Widget build(BuildContext context) {
    final vColors = AtelierColors.of(context);

    return CustomPaint(
      painter: _LiningPainter(
        lining: lining,
        windowHeightMm: windowHeightMm,
        depthMm: depthMm,
        slopeDeg: slopeDeg,
        ink: vColors.ink,
        tape: vColors.tape,
        glass: Theme.of(context).colorScheme.primary,
        style: TextStyle(fontFamily: handFont, fontSize: 18, color: vColors.ink),
      ),
    );
  }
}

class _LiningPainter extends CustomPainter {
  _LiningPainter({
    required this.lining,
    required this.windowHeightMm,
    required this.depthMm,
    required this.slopeDeg,
    required this.ink,
    required this.tape,
    required this.glass,
    required this.style,
  });

  final RoofLining lining;
  final int windowHeightMm;
  final int depthMm;
  final double slopeDeg;
  final Color ink;
  final Color tape;
  final Color glass;
  final TextStyle style;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vSlope = slopeDeg.clamp(5.0, 85.0) * math.pi / 180;
    final vAlong = Offset(math.cos(vSlope), math.sin(vSlope));
    // Points en millimètres, y vers le haut : fenêtre sur le toit, embrasure en dessous
    final vBottom = Offset.zero;
    final vTop = vAlong * windowHeightMm.toDouble();
    final vTopIn = vTop + Offset(lining.topMm.toDouble(), 0);
    final vBottomIn = vBottom + Offset(0, -lining.bottomMm.toDouble());
    final vExtra = math.max(300.0, windowHeightMm * 0.35);
    final vPoints = [
      vBottom - vAlong * vExtra,
      vTop + vAlong * vExtra,
      vBottomIn - vAlong * vExtra,
      vTopIn + vAlong * vExtra,
    ];
    final vMinX = vPoints.map((pPoint) => pPoint.dx).reduce(math.min);
    final vMaxX = vPoints.map((pPoint) => pPoint.dx).reduce(math.max);
    final vMinY = vPoints.map((pPoint) => pPoint.dy).reduce(math.min);
    final vMaxY = vPoints.map((pPoint) => pPoint.dy).reduce(math.max);
    const vMargin = 24.0;
    final vScale = math.min(
      (pSize.width - 2 * vMargin) / math.max(1, vMaxX - vMinX),
      (pSize.height - 2 * vMargin) / math.max(1, vMaxY - vMinY),
    );
    final vFloor = pSize.height - vMargin;
    Offset vAt(Offset pMm) =>
        Offset(vMargin + (pMm.dx - vMinX) * vScale, vFloor - (pMm.dy - vMinY) * vScale);

    // Embrasure surlignée : la lumière qui entre dans la pièce
    pCanvas.drawPath(
      Path()..addPolygon([vAt(vBottom), vAt(vTop), vAt(vTopIn), vAt(vBottomIn)], true),
      Paint()..color = tape.withValues(alpha: 0.3),
    );
    final vPencil = Paint()
      ..color = ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final vThin = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    // Couverture et plafond rampant, de part et d'autre de la fenêtre
    pencilLine(pCanvas, vAt(vBottom - vAlong * vExtra), vAt(vBottom), vPencil);
    pencilLine(pCanvas, vAt(vTop), vAt(vTop + vAlong * vExtra), vPencil);
    pencilLine(pCanvas, vAt(vBottomIn - vAlong * vExtra), vAt(vBottomIn), vThin);
    pencilLine(pCanvas, vAt(vTopIn), vAt(vTopIn + vAlong * vExtra), vThin);
    // Habillages : haut horizontal, bas vertical
    pencilLine(pCanvas, vAt(vTop), vAt(vTopIn), vPencil);
    pencilLine(pCanvas, vAt(vBottom), vAt(vBottomIn), vPencil);
    // Vitrage
    pCanvas.drawLine(
      vAt(vBottom),
      vAt(vTop),
      Paint()
        ..color = glass
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    String vCm(int pMm) => formatCentimetres(pMm);
    final vTopMiddle = (vAt(vTop) + vAt(vTopIn)) / 2;
    sketchLabel(pCanvas, vCm(lining.topMm), vTopMiddle + const Offset(0, -12), style);
    sketchLabel(
      pCanvas,
      vCm(lining.bottomMm),
      (vAt(vBottom) + vAt(vBottomIn)) / 2 + const Offset(-22, 0),
      style,
    );
    final vMeasure = Paint()
      ..color = ink.withValues(alpha: 0.85)
      ..strokeWidth = 1;
    dimensionLine(
      pCanvas,
      vAt(vBottomIn),
      vAt(vTopIn),
      vCm(lining.ceilingOpeningMm),
      vMeasure,
      style,
      pLabelShift: 16,
    );
  }

  @override
  bool shouldRepaint(_LiningPainter pOld) =>
      pOld.lining != lining || pOld.slopeDeg != slopeDeg || pOld.windowHeightMm != windowHeightMm;
}
