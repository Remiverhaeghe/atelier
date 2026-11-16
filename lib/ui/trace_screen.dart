import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/tracing.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'photos.dart';
import 'theme.dart';

/// Choisit la photo d'un plan papier, puis ouvre le décalque ; renvoie les murs tracés.
Future<List<Wall>?> tracePaperPlan(BuildContext pContext, {PhotoTaker? pImages}) async {
  final vPath = await (pImages ?? pickImage)('plan');
  if (vPath == null || !pContext.mounted) {
    return null;
  }

  return Navigator.push<List<Wall>>(
    pContext,
    MaterialPageRoute(
      builder: (_) => TraceScreen(picture: Image.file(File(vPath), fit: BoxFit.contain)),
    ),
  );
}

/// Décalque d'un plan papier : deux points d'une cote connue pour l'échelle, puis les coins de
/// la pièce dans l'ordre du tour.
class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key, required this.picture});

  /// Photo du plan, posée sous le tracé.
  final Widget picture;

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen> {
  final _scale = <PlanPoint>[];
  final _corners = <PlanPoint>[];
  int _knownMm = 1000;

  double get _mmPerPoint => _scale.length < 2 ? 0 : traceScale(_scale[0], _scale[1], _knownMm);

  void _tap(Offset pPosition) => setState(() {
    final vPoint = PlanPoint(pPosition.dx, pPosition.dy);
    if (_scale.length < 2) {
      _scale.add(vPoint);
    } else {
      _corners.add(vPoint);
    }
  });

  void _undo() => setState(() {
    if (_corners.isNotEmpty) {
      _corners.removeLast();
    } else if (_scale.isNotEmpty) {
      _scale.removeLast();
    }
  });

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vWalls = wallsFromCorners(_corners, _mmPerPoint);
    final vStep = _scale.length < 2 ? vText.traceStepScale : vText.traceStepCorners;

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.traceTitle),
        actions: [
          IconButton(
            tooltip: vText.traceUndo,
            icon: const Icon(Icons.undo),
            onPressed: _scale.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          IconLine(Icons.touch_app_outlined, vStep),
          const SizedBox(height: 8),
          SizedBox(
            height: 420,
            child: GestureDetector(
              key: const ValueKey('trace-area'),
              onTapUp: (pDetails) => _tap(pDetails.localPosition),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.picture,
                  CustomPaint(
                    painter: _TracePainter(
                      scale: _scale,
                      corners: _corners,
                      scaleColor: vTheme.colorScheme.error,
                      cornerColor: vTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          NumberField<int>(
            label: vText.traceKnown,
            initial: '$_knownMm',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _knownMm = pValue),
          ),
          if (vWalls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              vText.traceWalls(
                vWalls.length,
                vWalls.map((pWall) => formatCentimetres(pWall.lengthMm)).join(' · '),
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: vWalls.isEmpty ? null : () => Navigator.pop(context, vWalls),
            icon: const Icon(Icons.check),
            label: Text(vText.traceCreate),
          ),
          const SizedBox(height: 12),
          Text(vText.traceHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.scale,
    required this.corners,
    required this.scaleColor,
    required this.cornerColor,
  });

  final List<PlanPoint> scale;
  final List<PlanPoint> corners;
  final Color scaleColor;
  final Color cornerColor;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    Offset vAt(PlanPoint pPoint) => Offset(pPoint.x, pPoint.y);
    final vScalePaint = Paint()
      ..color = scaleColor
      ..strokeWidth = 3;
    final vCornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final vPoint in scale) {
      pCanvas.drawCircle(vAt(vPoint), 6, vScalePaint);
    }
    if (scale.length == 2) {
      pCanvas.drawLine(vAt(scale[0]), vAt(scale[1]), vScalePaint);
    }
    if (corners.isNotEmpty) {
      final vPath = Path()..moveTo(corners.first.x, corners.first.y);
      for (final vPoint in corners.skip(1)) {
        vPath.lineTo(vPoint.x, vPoint.y);
      }
      if (corners.length > 2) {
        vPath.close();
      }
      pCanvas.drawPath(vPath, vCornerPaint);
      for (final vPoint in corners) {
        pCanvas.drawCircle(vAt(vPoint), 5, vCornerPaint..style = PaintingStyle.fill);
        vCornerPaint.style = PaintingStyle.stroke;
      }
    }
  }

  @override
  bool shouldRepaint(_TracePainter pOld) => true;
}
