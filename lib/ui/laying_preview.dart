import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/laying_plan.dart';
import 'theme.dart';

/// Aperçu du plan de pose : chaque rangée en lames de chêne, plus foncées une fois posées.
class LayingPreview extends StatelessWidget {
  const LayingPreview({super.key, required this.plan, required this.laidRows});

  final LayingPlan plan;
  final List<int> laidRows;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vLength = _longestRow(plan);
    final vWidth = plan.rows.fold(0, (pSum, pRow) => pSum + pRow.widthMm);
    if (vLength == 0 || vWidth == 0) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: (vLength / vWidth).clamp(0.8, 2.2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: vTheme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vTheme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CustomPaint(
            painter: _LayingPainter(
              plan: plan,
              laidRows: laidRows.toSet(),
              colors: AtelierColors.of(context),
              joint: vTheme.colorScheme.surfaceContainerLowest,
            ),
          ),
        ),
      ),
    );
  }
}

int _longestRow(LayingPlan pPlan) => pPlan.rows.fold(
  0,
  (pMax, pRow) => math.max(pMax, pRow.runs.fold(0, (pSum, pRun) => pSum + pRun.lengthMm)),
);

class _LayingPainter extends CustomPainter {
  _LayingPainter({
    required this.plan,
    required this.laidRows,
    required this.colors,
    required this.joint,
  });

  final LayingPlan plan;
  final Set<int> laidRows;
  final AtelierColors colors;
  final Color joint;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vLength = _longestRow(plan);
    final vWidth = plan.rows.fold(0, (pSum, pRow) => pSum + pRow.widthMm);
    final vScale = math.min(pSize.width / vLength, pSize.height / vWidth);
    final vLeft = (pSize.width - vLength * vScale) / 2;
    // Première rangée en bas, contre le mur de départ, comme sur le plan de la pièce
    var vBottom = (pSize.height + vWidth * vScale) / 2;
    final vJoint = Paint()
      ..color = joint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final vRow in plan.rows) {
      final vHeight = vRow.widthMm * vScale;
      final vFill = Paint()..color = laidRows.contains(vRow.number) ? colors.woodLaid : colors.wood;
      var vX = vLeft;
      for (final vRun in vRow.runs) {
        for (final vPiece in vRun.pieces) {
          final vRect = Rect.fromLTWH(vX, vBottom - vHeight, vPiece * vScale, vHeight);
          pCanvas.drawRect(vRect, vFill);
          pCanvas.drawRect(vRect, vJoint);
          vX += vPiece * vScale;
        }
      }
      vBottom -= vHeight;
    }
  }

  @override
  bool shouldRepaint(_LayingPainter pOld) =>
      pOld.plan != plan || pOld.laidRows != laidRows || pOld.colors != colors;
}
