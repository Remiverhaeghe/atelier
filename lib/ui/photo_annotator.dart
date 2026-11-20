
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../storage/photo_store.dart';

typedef PhotoMark = ({double x, double y});

/// Photo avec ses cercles rouges, à la place qu'ils occupent sur l'image.
class MarkedPhoto extends StatelessWidget {
  const MarkedPhoto({super.key, required this.path, required this.marks, this.onTapAt});

  final String path;
  final List<PhotoMark> marks;

  /// Endroit touché, en fraction de la largeur et de la hauteur.
  final ValueChanged<PhotoMark>? onTapAt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (pContext, pConstraints) => GestureDetector(
      onTapUp: onTapAt == null
          ? null
          : (pDetails) => onTapAt!((
              x: (pDetails.localPosition.dx / pConstraints.maxWidth).clamp(0.0, 1.0),
              y: (pDetails.localPosition.dy / pConstraints.maxHeight).clamp(0.0, 1.0),
            )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: photoProvider(path),
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black12),
          ),
          CustomPaint(painter: _MarksPainter(marks, Theme.of(context).colorScheme.error)),
        ],
      ),
    ),
  );
}

class _MarksPainter extends CustomPainter {
  _MarksPainter(this.marks, this.color);

  final List<PhotoMark> marks;
  final Color color;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final vMark in marks) {
      pCanvas.drawCircle(
        Offset(vMark.x * pSize.width, vMark.y * pSize.height),
        pSize.shortestSide * 0.07,
        vPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarksPainter pOld) => pOld.marks != marks;
}

/// Entoure ce qui est à reprendre sur la photo : un appui pose un cercle, « Effacer » les retire.
Future<List<PhotoMark>?> annotatePhoto(
  BuildContext pContext,
  String pPath,
  List<PhotoMark> pMarks,
) => Navigator.push<List<PhotoMark>>(
  pContext,
  MaterialPageRoute(
    builder: (_) => _Annotator(path: pPath, initial: pMarks),
  ),
);

class _Annotator extends StatefulWidget {
  const _Annotator({required this.path, required this.initial});

  final String path;
  final List<PhotoMark> initial;

  @override
  State<_Annotator> createState() => _AnnotatorState();
}

class _AnnotatorState extends State<_Annotator> {
  late var _marks = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.annotateTitle),
        actions: [
          TextButton(
            onPressed: _marks.isEmpty ? null : () => setState(() => _marks = []),
            child: Text(vText.annotateClear),
          ),
          TextButton(onPressed: () => Navigator.pop(context, _marks), child: Text(vText.save)),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(vText.annotateHelp)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: MarkedPhoto(
                path: widget.path,
                marks: _marks,
                onTapAt: (pMark) => setState(() => _marks = [..._marks, pMark]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
