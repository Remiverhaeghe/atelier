import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/photo_measure.dart';
import '../logic/units.dart';
import '../storage/photo_store.dart';
import 'photos.dart';
import 'theme.dart';

/// Mesure sur une photo : les deux bouts d'un côté de l'étalon posé à plat (carte ou feuille
/// A4), puis les deux bouts de ce qu'on mesure.
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
  var _reference = MeasureReference.card;

  Future<void> _pick() async {
    final vPath = await (widget.images ?? pickImage)('mesure');
    if (vPath != null) {
      setState(() {
        _picture = Image(image: photoProvider(vPath), fit: BoxFit.contain);
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
        ? photoMeasureMm(
            _points[0],
            _points[1],
            _points[2],
            _points[3],
            pReferenceMm: _reference.sideMm,
          )
        : null;
    final vTouchReference = switch (_reference) {
      MeasureReference.card => vText.photoMeasureCard,
      MeasureReference.a4Long => vText.photoMeasureSheetLong,
      MeasureReference.a4Short => vText.photoMeasureSheetShort,
    };
    final vStep = switch (_points.length) {
      0 || 1 => vTouchReference,
      2 || 3 => vText.photoMeasureObject,
      _ => vMm == null ? vTouchReference : vText.photoMeasureResult(formatCentimetres(vMm)),
    };
    final vSpread = vMm == null
        ? null
        : photoMeasureSpreadMm(vMm, _points[0].distanceTo(_points[1]));

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
          Text(vText.photoMeasureReference, style: vTheme.textTheme.titleSmall),
          const SizedBox(height: 4),
          SegmentedButton<MeasureReference>(
            segments: [
              ButtonSegment(value: MeasureReference.card, label: Text(vText.photoMeasureRefCard)),
              ButtonSegment(
                value: MeasureReference.a4Long,
                label: Text(vText.photoMeasureRefA4Long),
              ),
              ButtonSegment(
                value: MeasureReference.a4Short,
                label: Text(vText.photoMeasureRefA4Short),
              ),
            ],
            selected: {_reference},
            onSelectionChanged: (pChoice) => setState(() {
              _reference = pChoice.first;
              // Les points touchés valaient pour l'ancien étalon
              _points.clear();
            }),
          ),
          const SizedBox(height: 12),
          if (vPicture == null)
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(vText.photoMeasurePick),
            )
          else ...[
            vMm != null ? BigFigure(vStep) : IconLine(Icons.touch_app_outlined, vStep),
            if (vSpread != null)
              IconLine(Icons.straighten, vText.photoMeasureSpread(formatCentimetres(vSpread))),
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
