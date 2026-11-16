import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/laying_plan.dart';
import '../logic/room.dart';
import 'room_plan.dart';
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
              startLabel: AppLocalizations.of(context).layingStart,
              labelStyle: vTheme.textTheme.labelMedium!.copyWith(
                fontFamily: titleFont,
                fontWeight: FontWeight.w700,
                color: AtelierColors.of(context).onTape,
              ),
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
    required this.startLabel,
    required this.labelStyle,
  });

  final String startLabel;
  final TextStyle labelStyle;
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

    // Départ : première rangée, contre le mur de pose, sur une étiquette jaune
    final vLabel = TextPainter(
      text: TextSpan(text: '↑ $startLabel', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final vStart = (pSize.height + vWidth * vScale) / 2;
    final vRect = Rect.fromLTWH(
      vLeft + 4,
      vStart - vLabel.height - 8,
      vLabel.width + 12,
      vLabel.height + 4,
    );
    pCanvas.drawRRect(
      RRect.fromRectAndRadius(vRect, const Radius.circular(4)),
      Paint()..color = colors.tape,
    );
    vLabel.paint(pCanvas, vRect.topLeft + const Offset(6, 2));
  }

  @override
  bool shouldRepaint(_LayingPainter pOld) =>
      pOld.plan != plan || pOld.laidRows != laidRows || pOld.colors != colors;
}

/// Motif de point de Hongrie dessiné dans la pièce : chevrons de lames à 45°, axe au centre.
class HerringbonePreview extends StatelessWidget {
  const HerringbonePreview({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: vTheme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vTheme.colorScheme.outlineVariant),
        ),
        child: CustomPaint(
          painter: _HerringbonePainter(room: room, colors: AtelierColors.of(context)),
        ),
      ),
    );
  }
}

class _HerringbonePainter extends CustomPainter {
  _HerringbonePainter({required this.room, required this.colors});

  final Room room;
  final AtelierColors colors;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (room.walls.length < 3) {
      return;
    }
    final vFrame = PlanFrame(room, pSize, pMargin: 12);
    final vPath = Path()
      ..addPolygon([for (final vPoint in outline(room)) vFrame.toScreen(vPoint.x, vPoint.y)], true);
    pCanvas.drawPath(vPath, Paint()..color = colors.wood);
    pCanvas.save();
    pCanvas.clipPath(vPath);
    final vJoint = Paint()
      ..color = colors.woodLaid
      ..strokeWidth = 1.2;
    // Lames de 60 × 9 cm environ à l'échelle : des chevrons qui montent vers l'axe central
    final vStep = (90 * vFrame.scale).clamp(4.0, 40.0);
    final vRise = vStep * 4;
    for (var vX = -vRise; vX < pSize.width + vRise; vX += vRise) {
      for (var vY = -vRise; vY < pSize.height + vRise; vY += vStep) {
        pCanvas.drawLine(Offset(vX, vY), Offset(vX + vRise / 2, vY - vRise / 2), vJoint);
        pCanvas.drawLine(Offset(vX + vRise / 2, vY - vRise / 2), Offset(vX + vRise, vY), vJoint);
      }
      final vAxis = Paint()
        ..color = colors.woodLaid
        ..strokeWidth = 2;
      pCanvas.drawLine(Offset(vX + vRise / 2, 0), Offset(vX + vRise / 2, pSize.height), vAxis);
    }
    pCanvas.restore();
    pCanvas.drawPath(
      vPath,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HerringbonePainter pOld) => pOld.room != room;
}
