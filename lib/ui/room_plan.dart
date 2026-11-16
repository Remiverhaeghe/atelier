import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/geometry.dart';
import '../logic/room.dart';

/// Plan de la pièce à l'échelle, murs numérotés ; [highlightWall] surligne un mur.
class RoomPlan extends StatelessWidget {
  const RoomPlan({super.key, required this.room, this.highlightWall});

  final Room room;
  final int? highlightWall;

  @override
  Widget build(BuildContext context) {
    final vColors = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: CustomPaint(
        painter: _RoomPlanPainter(
          room: room,
          lineColor: vColors.onSurface,
          highlightColor: vColors.primary,
          textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(color: vColors.onSurface),
          highlightWall: highlightWall,
        ),
      ),
    );
  }
}

class _RoomPlanPainter extends CustomPainter {
  _RoomPlanPainter({
    required this.room,
    required this.lineColor,
    required this.highlightColor,
    required this.textStyle,
    this.highlightWall,
  });

  final Room room;
  final Color lineColor;
  final Color highlightColor;
  final TextStyle textStyle;
  final int? highlightWall;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (room.walls.isEmpty) {
      return;
    }
    final vPoints = outline(room);
    final vMinX = vPoints.map((pPoint) => pPoint.x).reduce(math.min);
    final vMaxX = vPoints.map((pPoint) => pPoint.x).reduce(math.max);
    final vMinY = vPoints.map((pPoint) => pPoint.y).reduce(math.min);
    final vMaxY = vPoints.map((pPoint) => pPoint.y).reduce(math.max);
    const vMargin = 24.0;
    final vScale = math.min(
      (pSize.width - 2 * vMargin) / math.max(vMaxX - vMinX, 1),
      (pSize.height - 2 * vMargin) / math.max(vMaxY - vMinY, 1),
    );
    // Axe vertical inversé : le plan se lit comme sur papier.
    Offset vToScreen(PlanPoint pPoint) => Offset(
      vMargin + (pPoint.x - vMinX) * vScale,
      pSize.height - vMargin - (pPoint.y - vMinY) * vScale,
    );

    for (var vIndex = 0; vIndex < room.walls.length; vIndex++) {
      final vStart = vToScreen(vPoints[vIndex]);
      final vEnd = vToScreen(vPoints[vIndex + 1]);
      final vPaint = Paint()
        ..color = vIndex == highlightWall ? highlightColor : lineColor
        ..strokeWidth = vIndex == highlightWall ? 5 : 3
        ..strokeCap = StrokeCap.round;
      pCanvas.drawLine(vStart, vEnd, vPaint);
      final vLabel = TextPainter(
        text: TextSpan(text: '${vIndex + 1}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final vMiddle = (vStart + vEnd) / 2;
      vLabel.paint(pCanvas, vMiddle - Offset(vLabel.width / 2, vLabel.height + 4));
    }
  }

  @override
  bool shouldRepaint(_RoomPlanPainter pOld) =>
      pOld.room != room || pOld.highlightWall != highlightWall || pOld.lineColor != lineColor;
}
