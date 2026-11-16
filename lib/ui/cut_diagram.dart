import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/baseboard.dart';
import '../logic/units.dart';
import 'dialogs.dart';
import 'theme.dart';

/// Morceau de plinthe vu de dessus, tel qu'il est posé sur la scie à onglet : dos contre le
/// guide en haut, face vers soi en bas. Le trait de chaque bout est celui que suit la lame.
class CutDiagram extends StatelessWidget {
  const CutDiagram({super.key, required this.piece});

  final BaseboardPiece piece;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSmall = vTheme.textTheme.labelSmall!.copyWith(
      color: vTheme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      label: vText.cutDiagramLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(vText.cutBack, style: vSmall),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _CutPainter(
                piece: piece,
                colors: AtelierColors.of(context),
                wood: AtelierColors.of(context).woodLaid,
                line: vTheme.colorScheme.onSurface,
                angleStyle: vTheme.textTheme.labelMedium!.copyWith(
                  fontFamily: titleFont,
                  fontWeight: FontWeight.w700,
                  color: vTheme.colorScheme.primary,
                ),
                startAngle: _angleText(vText, piece.startCut),
                endAngle: _angleText(vText, piece.endCut),
                length: formatCentimetres(piece.lengthMm),
              ),
            ),
          ),
          Text(vText.cutFace, style: vSmall),
        ],
      ),
    );
  }

  String _angleText(AppLocalizations pText, EndCut pCut) => pCut.kind == EndCutKind.square
      ? pText.squareCutShort
      : pText.degrees(formatAngle(pCut.sawAngleDeg));
}

class _CutPainter extends CustomPainter {
  _CutPainter({
    required this.piece,
    required this.colors,
    required this.wood,
    required this.line,
    required this.angleStyle,
    required this.startAngle,
    required this.endAngle,
    required this.length,
  });

  final BaseboardPiece piece;
  final AtelierColors colors;
  final Color wood;
  final Color line;
  final TextStyle angleStyle;
  final String startAngle;
  final String endAngle;
  final String length;

  /// Décalage du bout entre le dos et la face, en pixels, pour l'angle de scie donné.
  double _slant(EndCut pCut, double pThickness) =>
      pThickness * math.tan(math.min(pCut.sawAngleDeg, 60) * math.pi / 180);

  @override
  void paint(Canvas pCanvas, Size pSize) {
    // Plinthe épaissie pour que l'angle se lise ; place à gauche et à droite pour les chutes
    const vThickness = 26.0;
    const vSide = 44.0;
    final vTop = (pSize.height - vThickness) / 2;
    final vBottom = vTop + vThickness;
    final vLeft = vSide;
    final vRight = pSize.width - vSide;

    final vStartSlant = _slant(piece.startCut, vThickness);
    final vEndSlant = _slant(piece.endCut, vThickness);
    // Pointe longue au dos (coin rentrant, début d'un biseau) ou sur la face (coin sortant)
    final vStartBackLonger = piece.startCut.kind != EndCutKind.outsideMiter;
    final vEndBackLonger = piece.endCut.kind == EndCutKind.insideMiter;

    final vBackStart = vStartBackLonger ? vLeft : vLeft + vStartSlant;
    final vFaceStart = vStartBackLonger ? vLeft + vStartSlant : vLeft;
    final vBackEnd = vEndBackLonger ? vRight : vRight - vEndSlant;
    final vFaceEnd = vEndBackLonger ? vRight - vEndSlant : vRight;

    // Barre entière en pointillé : ce qui dépasse du trait de coupe part en chute
    final vBar = Rect.fromLTRB(4, vTop, pSize.width - 4, vBottom);
    _paintOffcut(pCanvas, vBar);

    final vPiece = Path()
      ..moveTo(vBackStart, vTop)
      ..lineTo(vBackEnd, vTop)
      ..lineTo(vFaceEnd, vBottom)
      ..lineTo(vFaceStart, vBottom)
      ..close();
    pCanvas.drawPath(vPiece, Paint()..color = wood);
    pCanvas.drawPath(
      vPiece,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Traits de lame, prolongés au-delà de la plinthe
    final vBlade = Paint()
      ..color = colors.tape
      ..strokeWidth = 3;
    _paintBlade(pCanvas, Offset(vBackStart, vTop), Offset(vFaceStart, vBottom), vBlade);
    _paintBlade(pCanvas, Offset(vBackEnd, vTop), Offset(vFaceEnd, vBottom), vBlade);

    _paintText(pCanvas, startAngle, Offset(vLeft / 2 + 2, vBottom + 9), angleStyle);
    _paintText(pCanvas, endAngle, Offset(pSize.width - vSide / 2 - 2, vBottom + 9), angleStyle);
    _paintTape(pCanvas, length, Offset((vBackStart + vBackEnd) / 2, vTop));
  }

  void _paintOffcut(Canvas pCanvas, Rect pBar) {
    final vPaint = Paint()
      ..color = line.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const vDash = 5.0;
    for (final (vFrom, vTo) in [
      (pBar.topLeft, pBar.topRight),
      (pBar.bottomLeft, pBar.bottomRight),
    ]) {
      for (var vX = vFrom.dx; vX < vTo.dx; vX += 2 * vDash) {
        pCanvas.drawLine(
          Offset(vX, vFrom.dy),
          Offset(math.min(vX + vDash, vTo.dx), vFrom.dy),
          vPaint,
        );
      }
    }
  }

  void _paintBlade(Canvas pCanvas, Offset pBack, Offset pFace, Paint pPaint) {
    final vDirection = pFace - pBack;
    final vUnit = vDirection / vDirection.distance;
    pCanvas.drawLine(pBack - vUnit * 10, pFace + vUnit * 10, pPaint);
  }

  void _paintText(Canvas pCanvas, String pText, Offset pCenter, TextStyle pStyle) {
    final vLabel = TextPainter(
      text: TextSpan(text: pText, style: pStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    vLabel.paint(pCanvas, pCenter - Offset(vLabel.width / 2, vLabel.height / 2));
  }

  /// Longueur mesurée au dos, sur une étiquette jaune.
  void _paintTape(Canvas pCanvas, String pText, Offset pCenter) {
    final vLabel = TextPainter(
      text: TextSpan(
        text: pText,
        style: angleStyle.copyWith(color: colors.onTape),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
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

  @override
  bool shouldRepaint(_CutPainter pOld) =>
      pOld.piece != piece || pOld.colors != colors || pOld.length != length;
}
