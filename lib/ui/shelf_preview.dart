import 'package:flutter/material.dart';

import '../logic/shelf.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Étagère vue de face, à l'échelle : montants, tablettes régulièrement espacées, cotes.
class ShelfPreview extends StatelessWidget {
  const ShelfPreview({super.key, required this.design, required this.tooWide});

  final ShelfDesign design;

  /// Tablettes dessinées en rouge quand elles fléchiraient.
  final bool tooWide;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ShelfPainter(
          design: design,
          wood: AtelierColors.of(context).woodLaid,
          back: AtelierColors.of(context).wood,
          warning: tooWide ? vTheme.colorScheme.error : null,
          colors: AtelierColors.of(context),
          labelStyle: vTheme.textTheme.labelMedium!.copyWith(
            fontFamily: titleFont,
            fontWeight: FontWeight.w700,
            color: AtelierColors.of(context).onTape,
          ),
        ),
      ),
    );
  }
}

class _ShelfPainter extends CustomPainter {
  _ShelfPainter({
    required this.design,
    required this.wood,
    required this.back,
    required this.warning,
    required this.colors,
    required this.labelStyle,
  });

  final ShelfDesign design;
  final Color wood;
  final Color back;
  final Color? warning;
  final AtelierColors colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    if (design.widthMm <= 0 || design.heightMm <= 0) {
      return;
    }
    // Place à gauche et en bas pour les cotes
    const vMargin = 36.0;
    final vScale = [
      (pSize.width - 2 * vMargin) / design.widthMm,
      (pSize.height - vMargin - 8) / design.heightMm,
    ].reduce((pA, pB) => pA < pB ? pA : pB);
    final vWidth = design.widthMm * vScale;
    final vHeight = design.heightMm * vScale;
    final vLeft = (pSize.width - vWidth) / 2;
    const vTop = 8.0;
    final vThick = (design.thicknessMm * vScale).clamp(2.0, 12.0);
    final vWood = Paint()..color = wood;
    final vEdge = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    if (design.back) {
      pCanvas.drawRect(Rect.fromLTWH(vLeft, vTop, vWidth, vHeight), Paint()..color = back);
    }
    for (final vX in [vLeft, vLeft + vWidth - vThick]) {
      final vSide = Rect.fromLTWH(vX, vTop, vThick, vHeight);
      pCanvas.drawRect(vSide, vWood);
      pCanvas.drawRect(vSide, vEdge);
    }
    final vShelves = design.shelves < 2 ? 2 : design.shelves;
    for (var vIndex = 0; vIndex < vShelves; vIndex++) {
      final vY = vTop + (vHeight - vThick) * vIndex / (vShelves - 1);
      final vBoard = Rect.fromLTWH(vLeft + vThick, vY, vWidth - 2 * vThick, vThick);
      pCanvas.drawRect(vBoard, Paint()..color = warning ?? wood);
      pCanvas.drawRect(vBoard, vEdge);
    }
    _tape(pCanvas, formatCentimetres(design.widthMm), Offset(vLeft + vWidth / 2, vTop + vHeight + 16));
    _tape(pCanvas, formatCentimetres(design.heightMm), Offset(vLeft - 20, vTop + vHeight / 2));
  }

  void _tape(Canvas pCanvas, String pText, Offset pCenter) {
    final vLabel = TextPainter(
      text: TextSpan(text: pText, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final vRect = Rect.fromCenter(center: pCenter, width: vLabel.width + 12, height: vLabel.height + 4);
    pCanvas.drawRRect(RRect.fromRectAndRadius(vRect, const Radius.circular(4)), Paint()..color = colors.tape);
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  @override
  bool shouldRepaint(_ShelfPainter pOld) => pOld.design != design || pOld.warning != warning;
}
