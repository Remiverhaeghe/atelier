import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/stair_design.dart';
import '../logic/turning_stair.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'stair_railing_card.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';
import 'turning_stair_card.dart';

/// Escalier : coupe dessinée, trémie pour l'échappée, débit des limons et des marches, et
/// emprise d'un escalier quart tournant ou demi-tournant.
class StairCalculator extends StatefulWidget {
  const StairCalculator({super.key, this.riseMm = 2800});

  final int riseMm;

  @override
  State<StairCalculator> createState() => _StairCalculatorState();
}

class _StairCalculatorState extends State<StairCalculator> {
  late int _rise = widget.riseMm;
  int _width = 800;
  int? _tremie;
  var _shape = StairShape.straight;
  var _openSides = 1;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vDesign = designStair(_rise, pTremieMm: _tremie);
    final vPlan = vDesign.plan;
    String vCm(int pMm) => formatCentimetres(pMm);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.stairTitle),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: vText.stairTitle,
              intro: vText.stairHint,
              measures: [
                (vText.stairRise, vCm(_rise)),
                (vText.stairWidth, vCm(_width)),
                if (_tremie != null) (vText.stairTremieField, vCm(_tremie!)),
              ],
              results: [
                vText.stairSteps(vPlan.risers, vCm(vPlan.riserMm)),
                vText.stairGoing(vCm(vPlan.goingMm), vCm(vPlan.runMm)),
                vText.stairBlondel(vCm(2 * vPlan.riserMm + vPlan.goingMm)),
                vText.stairTreads(vDesign.treads, vCm(_width), vCm(vDesign.treadDepthMm)),
                vText.stairStringers(vCm(vDesign.stringerMm)),
                vDesign.headroomOk
                    ? vText.stairTremie(vCm(vDesign.tremieMm))
                    : vText.stairTremieShort(vCm(vDesign.tremieMm), vCm(_tremie!)),
              ],
              buy: const [],
              steps: const [],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _StairPainter(
                risers: vPlan.risers,
                riserMm: vPlan.riserMm,
                goingMm: vPlan.goingMm,
                riseMm: _rise,
                tremieMm: vDesign.tremieMm,
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
                  BigFigure(vText.stairSteps(vPlan.risers, vCm(vPlan.riserMm))),
                  Text(vText.stairGoing(vCm(vPlan.goingMm), vCm(vPlan.runMm))),
                  IconLine(
                    Icons.straighten,
                    vText.stairBlondel(vCm(2 * vPlan.riserMm + vPlan.goingMm)),
                  ),
                  IconLine(
                    Icons.crop_landscape,
                    vText.stairTreads(vDesign.treads, vCm(_width), vCm(vDesign.treadDepthMm)),
                  ),
                  IconLine(Icons.show_chart, vText.stairStringers(vCm(vDesign.stringerMm))),
                  IconLine(
                    vDesign.headroomOk ? Icons.check : AtelierIcons.warning,
                    vDesign.headroomOk
                        ? vText.stairTremie(vCm(vDesign.tremieMm))
                        : vText.stairTremieShort(vCm(vDesign.tremieMm), vCm(_tremie!)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TurningStairCard(
            riseMm: _rise,
            widthMm: _width,
            shape: _shape,
            onShape: (pShape) => setState(() => _shape = pShape),
          ),
          const SizedBox(height: 12),
          StairRailingCard(
            design: vDesign,
            riseMm: _rise,
            openSides: _openSides,
            onOpenSides: (pSides) => setState(() => _openSides = pSides),
          ),
          const SizedBox(height: 12),
          NumberField<int>(
            label: vText.stairRise,
            initial: vCm(_rise),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _rise = pValue),
          ),
          NumberField<int>(
            label: vText.stairWidth,
            initial: vCm(_width),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _width = pValue),
          ),
          NumberField<int>(
            label: vText.stairTremieField,
            initial: '',
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _tremie = pValue),
          ),
          const SizedBox(height: 8),
          Text(vText.stairHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Coupe de l'escalier : marches, plancher du haut et trémie.
class _StairPainter extends CustomPainter {
  _StairPainter({
    required this.risers,
    required this.riserMm,
    required this.goingMm,
    required this.riseMm,
    required this.tremieMm,
    required this.colors,
  });

  final int risers;
  final int riserMm;
  final int goingMm;
  final int riseMm;
  final int tremieMm;
  final AtelierColors colors;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vRun = (risers - 1) * goingMm;
    final vWidthMm = vRun + 800.0;
    final vHeightMm = riseMm + 400.0;
    final vScale = math.min(pSize.width / vWidthMm, pSize.height / vHeightMm);
    Offset vAt(double pX, double pY) => Offset(20 + pX * vScale, pSize.height - 10 - pY * vScale);
    final vInk = Paint()
      ..color = colors.ink
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final vPath = Path()..moveTo(vAt(0, 0).dx, vAt(0, 0).dy);
    for (var vStep = 0; vStep < risers; vStep++) {
      final vX = vStep * goingMm.toDouble();
      final vY = (vStep + 1) * riserMm.toDouble();
      vPath.lineTo(vAt(vX, vY).dx, vAt(vX, vY).dy);
      if (vStep < risers - 1) {
        vPath.lineTo(vAt(vX + goingMm, vY).dx, vAt(vX + goingMm, vY).dy);
      }
    }
    pCanvas.drawPath(vPath, vInk);
    // Sol et plancher du haut, ouvert sur la trémie
    pCanvas.drawLine(vAt(-200, 0), vAt(vWidthMm - 200, 0), vInk);
    final vFloorPaint = Paint()..color = colors.wood;
    final vTremieStart = vRun - tremieMm.toDouble();
    pCanvas.drawRect(
      Rect.fromPoints(
        vAt(-200, riseMm.toDouble()),
        vAt(vTremieStart, riseMm - upperFloorMm.toDouble()),
      ),
      vFloorPaint,
    );
    pCanvas.drawRect(
      Rect.fromPoints(
        vAt(vRun.toDouble(), riseMm.toDouble()),
        vAt(vWidthMm - 200, riseMm - upperFloorMm.toDouble()),
      ),
      vFloorPaint,
    );
  }

  @override
  bool shouldRepaint(_StairPainter pOld) =>
      pOld.risers != risers || pOld.tremieMm != tremieMm || pOld.riseMm != riseMm;
}
