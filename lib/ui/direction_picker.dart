import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/laying_direction.dart';
import '../logic/room.dart';
import 'room_plan.dart';
import 'theme.dart';

/// Choix du sens de pose en images : la pièce rayée de lames dans chaque sens possible.
class DirectionPicker extends StatelessWidget {
  const DirectionPicker({
    super.key,
    required this.room,
    required this.directions,
    required this.selected,
    required this.onSelected,
  });

  final Room room;
  final List<LayingDirection> directions;
  final int selected;
  final ValueChanged<LayingDirection> onSelected;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vText.layingDirectionTitle, style: vTheme.textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: directions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (pContext, pIndex) => _DirectionCard(
              room: room,
              direction: directions[pIndex],
              selected: pIndex == selected,
              onTap: () => onSelected(directions[pIndex]),
            ),
          ),
        ),
        const SizedBox(height: 8),
        IconLine(Icons.lightbulb_outline, vText.layingDirectionAdvice),
      ],
    );
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({
    required this.room,
    required this.direction,
    required this.selected,
    required this.onTap,
  });

  final Room room;
  final LayingDirection direction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vColors = vTheme.colorScheme;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: vColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? vColors.primary : vColors.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _StripesPainter(
                    room: room,
                    angleDeg: direction.angleDeg,
                    wood: AtelierColors.of(context).wood,
                    joint: AtelierColors.of(context).woodLaid,
                    ink: vColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(vText.alongWall(direction.wallIndex + 1), style: vTheme.textTheme.titleSmall),
              Text(vText.directionRows(direction.rowCount), style: vTheme.textTheme.bodySmall),
              if (direction.recommended)
                Text(
                  vText.recommended,
                  style: vTheme.textTheme.labelMedium!.copyWith(
                    color: vColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pièce remplie de lames parallèles à la direction donnée.
class _StripesPainter extends CustomPainter {
  _StripesPainter({
    required this.room,
    required this.angleDeg,
    required this.wood,
    required this.joint,
    required this.ink,
  });

  final Room room;
  final double angleDeg;
  final Color wood;
  final Color joint;
  final Color ink;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vFrame = PlanFrame(room, pSize, pMargin: 4);
    final vPoints = outline(room);
    final vPath = Path()
      ..addPolygon([for (final vPoint in vPoints) vFrame.toScreen(vPoint.x, vPoint.y)], true);
    pCanvas.drawPath(vPath, Paint()..color = wood);
    pCanvas.save();
    pCanvas.clipPath(vPath);
    // Le plan a l'axe vertical inversé : l'angle à l'écran change de signe.
    final vAngle = -angleDeg * math.pi / 180;
    final vAlong = Offset(math.cos(vAngle), math.sin(vAngle));
    final vAcross = Offset(-vAlong.dy, vAlong.dx);
    final vCenter = pSize.center(Offset.zero);
    final vReach = pSize.longestSide;
    final vPaint = Paint()
      ..color = joint
      ..strokeWidth = 1.2;
    for (var vStep = -vReach; vStep <= vReach; vStep += 7) {
      final vMiddle = vCenter + vAcross * vStep;
      pCanvas.drawLine(vMiddle - vAlong * vReach, vMiddle + vAlong * vReach, vPaint);
    }
    pCanvas.restore();
    pCanvas.drawPath(
      vPath,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_StripesPainter pOld) => pOld.room != room || pOld.angleDeg != angleDeg;
}
