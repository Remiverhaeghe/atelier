import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/photo_measure.dart';
import '../logic/units.dart';
import 'photos.dart';
import 'theme.dart';

/// Mesure sur une photo : les deux bouts du grand côté d'une carte posée à plat, puis les deux
/// bouts de ce qu'on mesure.
class PhotoMeasureScreen extends StatefulWidget {
  const PhotoMeasureScreen({super.key, this.images, this.picture});

  /// Choix de la photo ; remplaçable dans les tests.
  final PhotoTaker? images;

  /// Photo déjà choisie, pour les tests.
  final Widget? picture;

  @override
  State<PhotoMeasureScreen> createState() => _PhotoMeasureScreenState();
}

class _PhotoMeasureScreenState extends State<PhotoMeasureScreen> {
  late Widget? _picture = widget.picture;
  final _points = <PlanPoint>[];

  Future<void> _pick() async {
    final vPath = await (widget.images ?? pickImage)('mesure');
    if (vPath != null) {
      setState(() {
        _picture = Image.file(File(vPath), fit: BoxFit.contain);
        _points.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPicture = _picture;
    final vMm = _points.length == 4
        ? photoMeasureMm(_points[0], _points[1], _points[2], _points[3])
        : null;
    final vStep = switch (_points.length) {
      0 || 1 => vText.photoMeasureCard,
      2 || 3 => vText.photoMeasureObject,
      _ => vMm == null ? vText.photoMeasureCard : vText.photoMeasureResult(formatCentimetres(vMm)),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.photoMeasureTitle),
        actions: [
          IconButton(
            tooltip: vText.traceUndo,
            icon: const Icon(Icons.undo),
            onPressed: _points.isEmpty ? null : () => setState(_points.removeLast),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (vPicture == null)
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(vText.photoMeasurePick),
            )
          else ...[
            vMm != null
                ? BigFigure(vStep)
                : IconLine(Icons.touch_app_outlined, vStep),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: GestureDetector(
                key: const ValueKey('measure-area'),
                onTapUp: (pDetails) {
                  if (_points.length < 4) {
                    setState(
                      () => _points.add(
                        PlanPoint(pDetails.localPosition.dx, pDetails.localPosition.dy),
                      ),
                    );
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    vPicture,
                    CustomPaint(
                      painter: _MeasurePainter(
                        points: _points,
                        cardColor: vTheme.colorScheme.tertiary,
                        objectColor: vTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(vText.photoMeasureOther),
            ),
          ],
          const SizedBox(height: 12),
          Text(vText.photoMeasureHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MeasurePainter extends CustomPainter {
  _MeasurePainter({required this.points, required this.cardColor, required this.objectColor});

  final List<PlanPoint> points;
  final Color cardColor;
  final Color objectColor;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    for (var vIndex = 0; vIndex < points.length; vIndex++) {
      final vPaint = Paint()
        ..color = vIndex < 2 ? cardColor : objectColor
        ..strokeWidth = 3;
      final vPoint = Offset(points[vIndex].x, points[vIndex].y);
      pCanvas.drawCircle(vPoint, 6, vPaint);
      if (vIndex.isOdd) {
        pCanvas.drawLine(Offset(points[vIndex - 1].x, points[vIndex - 1].y), vPoint, vPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_MeasurePainter pOld) => true;
}
