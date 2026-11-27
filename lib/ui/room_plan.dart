import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixtures.dart';
import '../logic/furniture.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/slope.dart';
import '../logic/units.dart';
import 'networks_section.dart';
import 'plan_unit.dart';
import 'room_measure_picker.dart' show unitName;
import 'theme.dart';

/// Repère sur le plan : numéro de la reprise et position en millimètres.
typedef PlanMarker = ({int number, int xMm, int yMm, bool done});

/// Passage du plan (millimètres, axe vertical vers le haut) à l'écran, et retour.
class PlanFrame {
  PlanFrame(Room pRoom, Size pSize, {required double pMargin}) {
    final vPoints = outline(pRoom);
    minX = vPoints.map((pPoint) => pPoint.x).reduce(math.min);
    final vMaxX = vPoints.map((pPoint) => pPoint.x).reduce(math.max);
    minY = vPoints.map((pPoint) => pPoint.y).reduce(math.min);
    final vMaxY = vPoints.map((pPoint) => pPoint.y).reduce(math.max);
    scale = math.min(
      (pSize.width - 2 * pMargin) / math.max(vMaxX - minX, 1),
      (pSize.height - 2 * pMargin) / math.max(vMaxY - minY, 1),
    );
    // Plan centré, axe vertical inversé : il se lit comme sur papier.
    origin = Offset(
      (pSize.width - (vMaxX - minX) * scale) / 2,
      (pSize.height + (vMaxY - minY) * scale) / 2,
    );
  }

  late final double minX;
  late final double minY;
  late final double scale;
  late final Offset origin;

  Offset toScreen(double pX, double pY) =>
      origin + Offset((pX - minX) * scale, -(pY - minY) * scale);

  ({int xMm, int yMm}) toPlan(Offset pScreen) => (
    xMm: ((pScreen.dx - origin.dx) / scale + minX).round(),
    yMm: (-(pScreen.dy - origin.dy) / scale + minY).round(),
  );
}

/// Marge autour du plan : place pour les cotes, posées à l'extérieur des murs.
double _margin(bool pCompact) => pCompact ? 6.0 : 40.0;

/// Plan coté de la pièce, sur papier quadrillé ; [highlightWall] surligne un mur.
///
/// En [compact], vignette sans quadrillage ni cotes, pour les listes. [markers] place les
/// reprises ; [onTapPlan] reçoit l'endroit touché, en millimètres.
class RoomPlan extends StatelessWidget {
  const RoomPlan({
    super.key,
    required this.room,
    this.highlightWall,
    this.compact = false,
    this.markers = const [],
    this.onTapPlan,
    this.wallNumbers = true,
    this.simple = false,
  });

  final Room room;
  final int? highlightWall;
  final bool compact;
  final List<PlanMarker> markers;
  final void Function(int pXMm, int pYMm)? onTapPlan;

  /// Pastilles des numéros de mur ; masquées quand les repères des reprises en portent déjà.
  final bool wallNumbers;

  /// Plan allégé : murs, ouvertures et cotes seulement, sans quadrillage, éléments fixes, meubles
  /// ni lettres de coins.
  final bool simple;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vColors = AtelierColors.of(context);
    final vPainter = _RoomPlanPainter(
      room: room,
      unit: unitName(AppLocalizations.of(context), PlanUnit.of(context)),
      lengthUnit: PlanUnit.of(context),
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
      markers: markers,
      wallNumbers: wallNumbers,
      simple: simple,
      markerColor: vTheme.colorScheme.error,
      doneColor: vTheme.colorScheme.primary,
    );
    if (compact) {
      return CustomPaint(painter: vPainter);
    }

    final vText = AppLocalizations.of(context);

    return Semantics(
      label: vText.planSemantics(
        room.name,
        room.walls.length,
        room.walls.length >= 3 ? formatSquareMetres(floorAreaM2(room)) : '0',
      ),
      image: true,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: vTheme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: vTheme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: onTapPlan == null || room.walls.isEmpty
                ? CustomPaint(painter: vPainter)
                : LayoutBuilder(
                    builder: (pContext, pConstraints) => GestureDetector(
                      onTapUp: (pDetails) {
                        final vFrame = PlanFrame(
                          room,
                          pConstraints.biggest,
                          pMargin: _margin(compact),
                        );
                        final vPoint = vFrame.toPlan(pDetails.localPosition);
                        onTapPlan!(vPoint.xMm, vPoint.yMm);
                      },
                      child: CustomPaint(painter: vPainter, size: pConstraints.biggest),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoomPlanPainter extends CustomPainter {
  _RoomPlanPainter({
    required this.room,
    required this.unit,
    required this.lengthUnit,
    required this.colors,
    required this.highlightColor,
    required this.paper,
    required this.labelStyle,
    required this.compact,
    required this.markers,
    required this.wallNumbers,
    required this.simple,
    required this.markerColor,
    required this.doneColor,
    this.highlightWall,
  });

  final List<PlanMarker> markers;
  final bool wallNumbers;
  final bool simple;
  final Color markerColor;
  final Color doneColor;
  final Room room;

  /// Unité écrite après chaque longueur cotée.
  final String unit;

  /// Unité dans laquelle les longueurs cotées sont écrites.
  final FieldUnit lengthUnit;
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
    final vFrame = PlanFrame(room, pSize, pMargin: _margin(compact));
    final vScale = vFrame.scale;
    Offset vAt(double pX, double pY) => vFrame.toScreen(pX, pY);

    if (!compact && !simple) {
      _paintGrid(pCanvas, pSize, vAt(vFrame.minX, vFrame.minY), 1000 * vScale);
    }

    final vRoomPath = Path()
      ..addPolygon([for (final vPoint in vPoints) vAt(vPoint.x, vPoint.y)], room.closed);
    pCanvas.drawPath(vRoomPath, Paint()..color = paper);

    // Partie sous la pente du toit, grisée comme sous un rampant sur un plan d'architecte
    for (final vSloped in slopedOutlines(room)) {
      if (vSloped.length >= 3) {
        pCanvas.drawPath(
          Path()..addPolygon([for (final vPoint in vSloped) vAt(vPoint.x, vPoint.y)], true),
          Paint()..color = colors.grid,
        );
      }
    }
    // Ligne des 1,80 m : en deçà, le sol ne compte pas en surface habitable
    for (final (vFrom, vTo) in lowHeadroomLines(room)) {
      _paintDashedLine(
        pCanvas,
        vAt(vFrom.x, vFrom.y),
        vAt(vTo.x, vTo.y),
        Paint()
          ..color = colors.tape
          ..strokeWidth = compact ? 1 : 2,
        compact ? 3 : 6,
      );
    }

    for (var vIndex = 0; vIndex < room.walls.length; vIndex++) {
      final vWall = room.walls[vIndex];
      final vStart = vPoints[vIndex];
      final vEnd = vPoints[vIndex + 1];
      final vLength = math.max(vWall.lengthMm, 1).toDouble();
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

      // Réseaux cachés : un trait de couleur contre le mur, là où ils passent
      if (!compact) {
        for (final vRun in room.networks.where((pRun) => pRun.wallIndex == vIndex)) {
          final vPaint = Paint()
            ..color = networkColor(vRun.kind)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round;
          final vInside = 10 / vScale;
          pCanvas.drawLine(
            vAlong(vRun.fromAlongMm.toDouble(), vInside),
            vAlong(vRun.toAlongMm.toDouble(), vInside),
            vPaint,
          );
        }
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
        if (vOpening.kind == OpeningKind.window) {
          // Fenêtre : le mur continue, en double trait fin comme sur un plan d'architecte
          final vWindow = Paint()
            ..color = vWallPaint.color
            ..strokeWidth = compact ? vWallPaint.strokeWidth : 1.5;
          final vSide = compact ? 0.0 : 3 / vScale;
          pCanvas.drawLine(vAlong(vOpenStart, vSide), vAlong(vOpenEnd, vSide), vWindow);
          pCanvas.drawLine(vAlong(vOpenStart, -vSide), vAlong(vOpenEnd, -vSide), vWindow);
        }
        if (vOpening.kind == OpeningKind.door && !compact) {
          _paintDoor(
            pCanvas,
            vAlong(vOpenStart),
            vAlong(vOpenEnd),
            vAlong(vOpenStart, vOpenEnd - vOpenStart),
          );
        }
        vFrom = math.max(vFrom, vOpenEnd);
      }
      if (vFrom < vLength) {
        pCanvas.drawLine(vAlong(vFrom), vAlong(vLength), vWallPaint);
      }

      if (!compact) {
        final vMiddle = vLength / 2;
        if (wallNumbers && !simple) {
          _paintNumber(pCanvas, vAlong(vMiddle, 26 / vScale), '${vIndex + 1}', vHighlighted);
        }
        _paintTape(
          pCanvas,
          vAlong(vMiddle, -22 / vScale),
          '${lengthInUnit(vWall.lengthMm, lengthUnit)} $unit',
        );
      }
    }

    for (final vFixture in simple ? const <Fixture>[] : room.fixtures) {
      _paintFixture(pCanvas, vFixture, vAt);
    }

    // Meubles à l'échelle, et le débattement des portes pour voir ce qui gêne
    if (room.furniture.isNotEmpty && !compact && !simple) {
      for (var vWall = 0; vWall < room.walls.length; vWall++) {
        for (final vDoor in room.walls[vWall].openings.where(
          (pOpening) => pOpening.kind == OpeningKind.door,
        )) {
          final vSweep = doorSweep(room, vWall, vDoor);
          final vHinge = vAt(vSweep[0].x, vSweep[0].y);
          final vRadius = (vAt(vSweep[1].x, vSweep[1].y) - vHinge).distance;
          final vStart = (vAt(vSweep[1].x, vSweep[1].y) - vHinge).direction;
          final vEnd = (vAt(vSweep[3].x, vSweep[3].y) - vHinge).direction;
          var vSweepAngle = vEnd - vStart;
          if (vSweepAngle > math.pi) {
            vSweepAngle -= 2 * math.pi;
          } else if (vSweepAngle < -math.pi) {
            vSweepAngle += 2 * math.pi;
          }
          pCanvas.drawArc(
            Rect.fromCircle(center: vHinge, radius: vRadius),
            vStart,
            vSweepAngle,
            true,
            Paint()..color = colors.tape.withValues(alpha: 0.25),
          );
        }
      }
    }
    for (final vItem in room.furniture.where((pItem) => !simple)) {
      final vPath = Path()
        ..addPolygon([for (final vCorner in vItem.corners) vAt(vCorner.x, vCorner.y)], true);
      pCanvas.drawPath(vPath, Paint()..color = colors.wood.withValues(alpha: 0.8));
      pCanvas.drawPath(
        vPath,
        Paint()
          ..color = colors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = compact ? 0.8 : 1.4,
      );
    }

    if (!compact && !simple && wallNumbers) {
      // Lettres des coins, reprises dans la saisie guidée : « du coin A au coin B ».
      // Une pièce qui se referme ne répète pas le coin A à la fin du dernier mur.
      final vLast = room.closed && room.walls.length >= 3 && closesProperly(room)
          ? room.walls.length - 1
          : room.walls.length;
      for (var vIndex = 0; vIndex <= vLast; vIndex++) {
        final vHighlighted =
            highlightWall != null && (vIndex == highlightWall || vIndex == highlightWall! + 1);
        _paintCorner(
          pCanvas,
          vAt(vPoints[vIndex].x, vPoints[vIndex].y),
          cornerName(vIndex),
          vHighlighted,
        );
      }
    }

    for (final vMarker in markers) {
      _paintMarker(pCanvas, vAt(vMarker.xMm.toDouble(), vMarker.yMm.toDouble()), vMarker);
    }
  }

  /// Lettre d'un coin, en carré pour ne pas la confondre avec le numéro rond d'un mur.
  void _paintCorner(Canvas pCanvas, Offset pCenter, String pName, bool pHighlighted) {
    final vLabel = _layout(pName, labelStyle.copyWith(color: pHighlighted ? paper : colors.ink));
    final vRect = Rect.fromCenter(
      center: pCenter,
      width: math.max(vLabel.width + 8, 18),
      height: vLabel.height + 2,
    );
    final vShape = RRect.fromRectAndRadius(vRect, const Radius.circular(4));
    pCanvas.drawRRect(vShape, Paint()..color = pHighlighted ? highlightColor : paper);
    pCanvas.drawRRect(
      vShape,
      Paint()
        ..color = pHighlighted ? highlightColor : colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  /// Prise, interrupteur, escalier, mezzanine ou fenêtre de toit, avec les signes d'un plan.
  void _paintFixture(Canvas pCanvas, Fixture pFixture, Offset Function(double, double) pAt) {
    final vStroke = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1 : 1.5;
    final vCenter = pAt(pFixture.xMm.toDouble(), pFixture.yMm.toDouble());
    if (!hasArea(pFixture.kind)) {
      if (compact) {
        return;
      }
      pCanvas.drawCircle(vCenter, 7, Paint()..color = paper);
      pCanvas.drawCircle(vCenter, 7, vStroke);
      if (pFixture.kind == FixtureKind.socket) {
        // Prise : deux broches
        pCanvas.drawCircle(vCenter - const Offset(2.5, 0), 1.3, Paint()..color = colors.ink);
        pCanvas.drawCircle(vCenter + const Offset(2.5, 0), 1.3, Paint()..color = colors.ink);
      } else {
        // Interrupteur : la manette
        pCanvas.drawLine(vCenter, vCenter + const Offset(9, -9), vStroke);
      }
      return;
    }
    final vHalfW = pFixture.widthMm / 2;
    final vHalfD = pFixture.depthMm / 2;
    final vX = pFixture.xMm.toDouble();
    final vY = pFixture.yMm.toDouble();
    final vRect = Rect.fromPoints(pAt(vX - vHalfW, vY - vHalfD), pAt(vX + vHalfW, vY + vHalfD));
    switch (pFixture.kind) {
      case FixtureKind.stairs:
        pCanvas.drawRect(vRect, Paint()..color = paper);
        pCanvas.drawRect(vRect, vStroke);
        // Une ligne par marche, le long de la longueur
        final vSteps = math.max(stairPlan(pFixture.riseMm ?? 2700).risers - 1, 1);
        for (var vStep = 1; vStep < vSteps; vStep++) {
          final vYStep = vRect.top + vRect.height * vStep / vSteps;
          pCanvas.drawLine(Offset(vRect.left, vYStep), Offset(vRect.right, vYStep), vStroke);
        }
      case FixtureKind.mezzanine:
        if (pFixture.hasNotch) {
          // Mezzanine en L : le contour longe la découpe laissée à l'escalier
          final vOutline = [for (final (vPx, vPy) in pFixture.outlineMm()) pAt(vPx, vPy)];
          for (var vIndex = 0; vIndex < vOutline.length; vIndex++) {
            _paintDashedLine(
              pCanvas,
              vOutline[vIndex],
              vOutline[(vIndex + 1) % vOutline.length],
              vStroke,
              compact ? 3 : 6,
            );
          }
        } else {
          _paintDashed(pCanvas, vRect, vStroke);
        }
      case FixtureKind.roofWindow:
        pCanvas.drawRect(vRect, Paint()..color = colors.grid);
        pCanvas.drawRect(vRect, vStroke);
        pCanvas.drawRect(vRect.deflate(compact ? 1 : 3), vStroke);
      case FixtureKind.stairwell:
        // Trémie : vide dans le sol, barré d'une croix comme sur un plan d'étage
        pCanvas.drawRect(vRect, Paint()..color = colors.grid);
        pCanvas.drawRect(vRect, vStroke);
        pCanvas.drawLine(vRect.topLeft, vRect.bottomRight, vStroke);
        pCanvas.drawLine(vRect.topRight, vRect.bottomLeft, vStroke);
      case FixtureKind.socket || FixtureKind.lightSwitch:
        break;
    }
  }

  /// Trait en tirets entre deux points.
  void _paintDashedLine(Canvas pCanvas, Offset pFrom, Offset pTo, Paint pPaint, double pDash) {
    final vLength = (pTo - pFrom).distance;
    if (vLength == 0) {
      return;
    }
    for (var vDone = 0.0; vDone < vLength; vDone += 2 * pDash) {
      final vEnd = math.min(vDone + pDash, vLength);
      pCanvas.drawLine(
        Offset.lerp(pFrom, pTo, vDone / vLength)!,
        Offset.lerp(pFrom, pTo, vEnd / vLength)!,
        pPaint,
      );
    }
  }

  /// Contour en tirets : la mezzanine est au-dessus, comme une poutre sur un plan.
  void _paintDashed(Canvas pCanvas, Rect pRect, Paint pPaint) {
    final vCorners = [pRect.topLeft, pRect.topRight, pRect.bottomRight, pRect.bottomLeft];
    for (var vIndex = 0; vIndex < 4; vIndex++) {
      final vFrom = vCorners[vIndex];
      final vTo = vCorners[(vIndex + 1) % 4];
      final vLength = (vTo - vFrom).distance;
      final vDash = compact ? 3.0 : 8.0;
      for (var vDone = 0.0; vDone < vLength; vDone += 2 * vDash) {
        final vEnd = math.min(vDone + vDash, vLength);
        pCanvas.drawLine(
          Offset.lerp(vFrom, vTo, vDone / vLength)!,
          Offset.lerp(vFrom, vTo, vEnd / vLength)!,
          pPaint,
        );
      }
    }
  }

  /// Repère d'une reprise : pastille numérotée, rouge à faire, verte une fois faite.
  void _paintMarker(Canvas pCanvas, Offset pCenter, PlanMarker pMarker) {
    final vColor = pMarker.done ? doneColor : markerColor;
    final vRadius = compact ? 3.0 : 11.0;
    pCanvas.drawCircle(pCenter, vRadius + (compact ? 0 : 2), Paint()..color = paper);
    pCanvas.drawCircle(pCenter, vRadius, Paint()..color = vColor);
    if (compact) {
      return;
    }
    final vLabel = _layout('${pMarker.number}', labelStyle.copyWith(color: paper));
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
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
      pOld.markers != markers ||
      pOld.colors != colors ||
      pOld.compact != compact ||
      pOld.unit != unit ||
      pOld.simple != simple ||
      pOld.lengthUnit != lengthUnit;
}
