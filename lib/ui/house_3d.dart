import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/room.dart';
import '../logic/view3d.dart';
import 'motion.dart';
import 'theme.dart';

/// Maison en 3D, à faire tourner d'un glissement du doigt. Elle se pose d'un quart de tour à
/// l'ouverture, sauf quand le téléphone réduit les animations.
///
/// En [simple], seulement le sol, les murs et les ouvertures : ni meubles ni structures.
class House3d extends StatefulWidget {
  const House3d({super.key, required this.rooms, this.simple = false});

  final List<Room> rooms;
  final bool simple;

  @override
  State<House3d> createState() => _House3dState();
}

class _House3dState extends State<House3d> with SingleTickerProviderStateMixin {
  static const _restYaw = 30.0;
  static const _introTurn = 70.0;

  late final AnimationController _intro = AnimationController(vsync: this);
  var _touched = false;

  /// Angle de vue : l'angle de repos, plus ce qui reste du quart de tour d'arrivée.
  double get _yaw => _touched
      ? _dragYaw
      : _restYaw + _introTurn * (1 - Curves.easeOutCubic.transform(_intro.value));
  var _dragYaw = _restYaw;

  @override
  void initState() {
    super.initState();
    _intro.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vDuration = motionDuration(context, 700);
    if (vDuration == Duration.zero) {
      _intro.value = 1;
    } else if (!_intro.isAnimating && _intro.value == 0) {
      unawaited(_intro.animateTo(1, duration: vDuration));
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragStart: (_) {
        _dragYaw = _yaw;
        _touched = true;
        _intro.stop();
      },
      onHorizontalDragUpdate: (pDetails) =>
          setState(() => _dragYaw = (_dragYaw + pDetails.delta.dx * 0.5) % 360),
      child: CustomPaint(
        size: Size.infinite,
        painter: _House3dPainter(
          faces: [
            for (final vFace in houseFaces(widget.rooms, _yaw))
              if (!widget.simple ||
                  vFace.kind != FaceKind.furniture && vFace.kind != FaceKind.structure)
                vFace,
          ],
          yaw: _yaw,
          colors: AtelierColors.of(context),
          wall: vTheme.colorScheme.surfaceContainerLowest,
          window: vTheme.colorScheme.primaryContainer,
        ),
      ),
    );
  }
}

class _House3dPainter extends CustomPainter {
  _House3dPainter({
    required this.faces,
    required this.yaw,
    required this.colors,
    required this.wall,
    required this.window,
  });

  final List<Face> faces;
  final double yaw;
  final AtelierColors colors;
  final Color wall;
  final Color window;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (faces.isEmpty) {
      return;
    }
    final vProjected = [
      for (final vFace in faces) [for (final vCorner in vFace.corners) project(vCorner, yaw)],
    ];
    final vXs = [for (final vFace in vProjected) ...vFace.map((pPoint) => pPoint.x)];
    final vYs = [for (final vFace in vProjected) ...vFace.map((pPoint) => pPoint.y)];
    final vMinX = vXs.reduce(math.min);
    final vMinY = vYs.reduce(math.min);
    final vScale = math.min(
      (pSize.width - 32) / math.max(vXs.reduce(math.max) - vMinX, 1),
      (pSize.height - 32) / math.max(vYs.reduce(math.max) - vMinY, 1),
    );
    final vOffset = Offset(
      (pSize.width - (vXs.reduce(math.max) - vMinX) * vScale) / 2,
      (pSize.height - (vYs.reduce(math.max) - vMinY) * vScale) / 2,
    );
    final vEdge = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var vIndex = 0; vIndex < faces.length; vIndex++) {
      final vPath = Path()
        ..addPolygon([
          for (final vPoint in vProjected[vIndex])
            vOffset + Offset((vPoint.x - vMinX) * vScale, (vPoint.y - vMinY) * vScale),
        ], true);
      final vFill = switch (faces[vIndex].kind) {
        FaceKind.floor => colors.woodLaid,
        FaceKind.wall => wall.withValues(alpha: 0.85),
        FaceKind.door => colors.wood,
        FaceKind.window => window,
        FaceKind.furniture => colors.wood.withValues(alpha: 0.9),
        FaceKind.structure => colors.wood,
      };
      pCanvas.drawPath(vPath, Paint()..color = vFill);
      pCanvas.drawPath(vPath, vEdge);
    }
  }

  @override
  bool shouldRepaint(_House3dPainter pOld) => pOld.yaw != yaw || pOld.faces != faces;
}
