import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/room.dart';
import '../logic/view3d.dart';
import 'theme.dart';

/// Maison en 3D, à faire tourner d'un glissement du doigt.
class House3d extends StatefulWidget {
  const House3d({super.key, required this.rooms});

  final List<Room> rooms;

  @override
  State<House3d> createState() => _House3dState();
}

class _House3dState extends State<House3d> {
  var _yaw = 30.0;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return GestureDetector(
      onHorizontalDragUpdate: (pDetails) => setState(() => _yaw = (_yaw + pDetails.delta.dx * 0.5) % 360),
      child: CustomPaint(
        size: Size.infinite,
        painter: _House3dPainter(
          faces: houseFaces(widget.rooms, _yaw),
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
      };
      pCanvas.drawPath(vPath, Paint()..color = vFill);
      pCanvas.drawPath(vPath, vEdge);
    }
  }

  @override
  bool shouldRepaint(_House3dPainter pOld) => pOld.yaw != yaw || pOld.faces != faces;
}
