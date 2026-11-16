import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Plan coté de la pièce, sur papier quadrillé ; [highlightWall] surligne un mur.
///
/// En [compact], vignette sans quadrillage ni cotes, pour les listes.
class RoomPlan extends StatelessWidget {
  const RoomPlan({super.key, required this.room, this.highlightWall, this.compact = false});

  final Room room;
  final int? highlightWall;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vColors = AtelierColors.of(context);
    final vPainter = _RoomPlanPainter(
      room: room,
      colors: vColors,
      highlightColor: vTheme.colorScheme.primary,
      paper: vTheme.colorScheme.surfaceContainerLowest,
      labelStyle: vTheme.textTheme.labelMedium!.copyWith(
        fontFamily: titleFont,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      highlightWall: highlightWall,
      compact: compact,
    );
    if (compact) {
      return CustomPaint(painter: vPainter);
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: vTheme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vTheme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(painter: vPainter),
        ),
      ),
    );
  }
}

class _RoomPlanPainter extends CustomPainter {
  _RoomPlanPainter({
    required this.room,
    required this.colors,
    required this.highlightColor,
    required this.paper,
    required this.labelStyle,
    required this.compact,
    this.highlightWall,
  });

  final Room room;
  final AtelierColors colors;
  final Color highlightColor;
  final Color paper;
  final TextStyle labelStyle;
  final bool compact;
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
    // Place pour les cotes, posées à l'extérieur des murs
    final vMargin = compact ? 6.0 : 40.0;
    final vScale = math.min(
      (pSize.width - 2 * vMargin) / math.max(vMaxX - vMinX, 1),
      (pSize.height - 2 * vMargin) / math.max(vMaxY - vMinY, 1),
    );
    // Plan centré, axe vertical inversé : il se lit comme sur papier.
    final vOrigin = Offset(
      (pSize.width - (vMaxX - vMinX) * vScale) / 2,
      (pSize.height + (vMaxY - vMinY) * vScale) / 2,
    );
    Offset vAt(double pX, double pY) =>
        vOrigin + Offset((pX - vMinX) * vScale, -(pY - vMinY) * vScale);

    if (!compact) {
      _paintGrid(pCanvas, pSize, vAt(vMinX, vMinY), 1000 * vScale);
    }

    final vRoomPath = Path()..addPolygon([for (final vPoint in vPoints) vAt(vPoint.x, vPoint.y)], room.closed);
    pCanvas.drawPath(vRoomPath, Paint()..color = paper);

    for (var vIndex = 0; vIndex < room.walls.length; vIndex++) {
      final vWall = room.walls[vIndex];
      final vStart = vPoints[vIndex];
      final vEnd = vPoints[vIndex + 1];
      final vLength = math.max(vWall.lengthMm.toDouble(), 1);
      // Direction du mur et normale vers l'intérieur (murs dans le sens inverse des aiguilles d'une montre)
      final vDirX = (vEnd.x - vStart.x) / vLength;
      final vDirY = (vEnd.y - vStart.y) / vLength;
      Offset vAlong(double pMm, [double pInsideMm = 0]) => vAt(
        vStart.x + vDirX * pMm - vDirY * pInsideMm,
        vStart.y + vDirY * pMm + vDirX * pInsideMm,
      );

      for (final vObstacle in room.obstacles.where((pObstacle) => pObstacle.wallIndex == vIndex)) {
        final vDepth = math.max(vObstacle.depthMm, 120).toDouble();
        _paintHatched(pCanvas, [
          vAlong(vObstacle.offsetMm.toDouble()),
          vAlong((vObstacle.offsetMm + vObstacle.widthMm).toDouble()),
          vAlong((vObstacle.offsetMm + vObstacle.widthMm).toDouble(), vDepth),
          vAlong(vObstacle.offsetMm.toDouble(), vDepth),
        ]);
      }

      final vHighlighted = vIndex == highlightWall;
      final vWallPaint = Paint()
        ..color = vHighlighted ? highlightColor : colors.ink
        ..strokeWidth = compact ? 2.5 : (vHighlighted ? 8 : 6)
        ..strokeCap = StrokeCap.square;
      final vOpenings = [...vWall.openings]..sort((pA, pB) => pA.offsetMm.compareTo(pB.offsetMm));
      var vFrom = 0.0;
      for (final vOpening in vOpenings) {
        final vOpenStart = vOpening.offsetMm.toDouble();
        final vOpenEnd = (vOpening.offsetMm + vOpening.widthMm).toDouble();
        if (vOpenStart > vFrom) {
          pCanvas.drawLine(vAlong(vFrom), vAlong(vOpenStart), vWallPaint);
        }
        if (vOpening.kind == OpeningKind.door && !compact) {
          _paintDoor(pCanvas, vAlong(vOpenStart), vAlong(vOpenEnd), vAlong(vOpenStart, vOpenEnd - vOpenStart));
        }
        vFrom = math.max(vFrom, vOpenEnd);
      }
      if (vFrom < vLength) {
        pCanvas.drawLine(vAlong(vFrom), vAlong(vLength), vWallPaint);
      }

      if (!compact) {
        final vMiddle = vLength / 2;
        _paintNumber(pCanvas, vAlong(vMiddle, 26 / vScale), '${vIndex + 1}', vHighlighted);
        _paintTape(pCanvas, vAlong(vMiddle, -22 / vScale), formatCentimetres(vWall.lengthMm));
      }
    }
  }

  /// Papier quadrillé, un carreau par mètre, calé sur le coin du plan.
  void _paintGrid(Canvas pCanvas, Size pSize, Offset pCorner, double pStep) {
    if (pStep < 8) {
      return;
    }
    final vPaint = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;
    for (var vX = pCorner.dx % pStep; vX < pSize.width; vX += pStep) {
      pCanvas.drawLine(Offset(vX, 0), Offset(vX, pSize.height), vPaint);
    }
    for (var vY = pCorner.dy % pStep; vY < pSize.height; vY += pStep) {
      pCanvas.drawLine(Offset(0, vY), Offset(pSize.width, vY), vPaint);
    }
  }

  /// Obstacle hachuré, comme sur un plan d'architecte.
  void _paintHatched(Canvas pCanvas, List<Offset> pCorners) {
    final vPath = Path()..addPolygon(pCorners, true);
    pCanvas.drawPath(vPath, Paint()..color = colors.grid);
    pCanvas.save();
    pCanvas.clipPath(vPath);
    final vBounds = vPath.getBounds();
    final vPaint = Paint()
      ..color = colors.ink.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    for (var vX = vBounds.left - vBounds.height; vX < vBounds.right; vX += 6) {
      pCanvas.drawLine(
        Offset(vX, vBounds.bottom),
        Offset(vX + vBounds.height, vBounds.top),
        vPaint,
      );
    }
    pCanvas.restore();
    pCanvas.drawPath(
      vPath,
      Paint()
        ..color = colors.ink.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// Porte : vantail ouvert vers l'intérieur et arc de son débattement.
  void _paintDoor(Canvas pCanvas, Offset pHinge, Offset pClosed, Offset pOpen) {
    final vPaint = Paint()
      ..color = colors.ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    pCanvas.drawLine(pHinge, pOpen, vPaint);
    final vRadius = (pClosed - pHinge).distance;
    final vFrom = (pClosed - pHinge).direction;
    var vSweep = (pOpen - pHinge).direction - vFrom;
    if (vSweep > math.pi) {
      vSweep -= 2 * math.pi;
    } else if (vSweep < -math.pi) {
      vSweep += 2 * math.pi;
    }
    pCanvas.drawArc(Rect.fromCircle(center: pHinge, radius: vRadius), vFrom, vSweep, false, vPaint);
  }

  /// Numéro du mur, dans une pastille côté pièce.
  void _paintNumber(Canvas pCanvas, Offset pCenter, String pText, bool pHighlighted) {
    final vLabel = _layout(pText, labelStyle.copyWith(color: pHighlighted ? paper : colors.ink));
    final vRadius = math.max(vLabel.width, vLabel.height) / 2 + 4;
    pCanvas.drawCircle(pCenter, vRadius, Paint()..color = pHighlighted ? highlightColor : paper);
    pCanvas.drawCircle(
      pCenter,
      vRadius,
      Paint()
        ..color = pHighlighted ? highlightColor : colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  /// Cote du mur en centimètres, sur une étiquette jaune mètre ruban.
  void _paintTape(Canvas pCanvas, Offset pCenter, String pText) {
    final vLabel = _layout(pText, labelStyle.copyWith(color: colors.onTape));
    final vRect = Rect.fromCenter(
      center: pCenter,
      width: vLabel.width + 12,
      height: vLabel.height + 4,
    );
    pCanvas.drawRRect(
      RRect.fromRectAndRadius(vRect, const Radius.circular(4)),
      Paint()..color = colors.tape,
    );
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  TextPainter _layout(String pText, TextStyle pStyle) => TextPainter(
    text: TextSpan(text: pText, style: pStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  bool shouldRepaint(_RoomPlanPainter pOld) =>
      pOld.room != room ||
      pOld.highlightWall != highlightWall ||
      pOld.colors != colors ||
      pOld.compact != compact;
}
