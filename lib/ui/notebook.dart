import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Pas du quadrillage du carnet, en pixels logiques ; une ligne plus marquée tous les cinq.
const notebookGridStep = 20.0;

/// Fond de page du carnet d'atelier : papier quadrillé. En mode nuit, fond uni.
class NotebookPaper extends StatelessWidget {
  const NotebookPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);
    final vColors = vTheme.extension<AtelierColors>();
    // Le mode nuit garde un fond noir uni : le quadrillage éclairerait l'écran
    final vPlain = vTheme.scaffoldBackgroundColor.a > 0;

    return CustomPaint(
      painter: _GridPainter(
        paper: vPlain ? vTheme.scaffoldBackgroundColor : vTheme.colorScheme.surface,
        line: vPlain || vColors == null ? null : vColors.grid,
      ),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.paper, required this.line});

  final Color paper;
  final Color? line;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    pCanvas.drawRect(Offset.zero & pSize, Paint()..color = paper);
    final vLine = line;
    if (vLine == null) {
      return;
    }
    final vThin = Paint()
      ..color = vLine.withValues(alpha: vLine.a * 0.55)
      ..strokeWidth = 0.6;
    final vThick = Paint()
      ..color = vLine
      ..strokeWidth = 1;
    var vIndex = 0;
    for (var vX = 0.0; vX <= pSize.width; vX += notebookGridStep) {
      pCanvas.drawLine(Offset(vX, 0), Offset(vX, pSize.height), vIndex++ % 5 == 0 ? vThick : vThin);
    }
    vIndex = 0;
    for (var vY = 0.0; vY <= pSize.height; vY += notebookGridStep) {
      pCanvas.drawLine(Offset(0, vY), Offset(pSize.width, vY), vIndex++ % 5 == 0 ? vThick : vThin);
    }
  }

  @override
  bool shouldRepaint(_GridPainter pOld) => pOld.paper != paper || pOld.line != line;
}

/// Transitions de page qui posent chaque écran sur sa propre feuille du carnet : les écrans
/// ont un fond transparent, la feuille est opaque, l'écran du dessous ne se voit jamais.
class NotebookPageTransitionsBuilder extends PageTransitionsBuilder {
  const NotebookPageTransitionsBuilder();

  static const _base = ZoomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> pRoute,
    BuildContext pContext,
    Animation<double> pAnimation,
    Animation<double> pSecondaryAnimation,
    Widget pChild,
  ) => _base.buildTransitions(
    pRoute,
    pContext,
    pAnimation,
    pSecondaryAnimation,
    NotebookPaper(child: pChild),
  );
}

/// Trait de crayon : un très léger tremblé, toujours le même pour une même ligne, pour que le
/// croquis ait l'air dessiné à la main sans bouger d'une image à l'autre.
void pencilLine(Canvas pCanvas, Offset pFrom, Offset pTo, Paint pPaint) {
  final vDelta = pTo - pFrom;
  final vLength = vDelta.distance;
  if (vLength < 1) {
    return;
  }
  final vNormal = Offset(-vDelta.dy, vDelta.dx) / vLength;
  final vSeed = (pFrom.dx * 7 + pFrom.dy * 13 + pTo.dx * 17 + pTo.dy * 19).round();
  final vSteps = math.max(2, (vLength / 14).round());
  final vPath = Path()..moveTo(pFrom.dx, pFrom.dy);
  for (var vStep = 1; vStep <= vSteps; vStep++) {
    final vT = vStep / vSteps;
    // Bruit déterministe, nul aux deux bouts pour que les traits se rejoignent
    final vWobble = vStep == vSteps ? 0.0 : math.sin((vSeed + vStep) * 12.9898) * 0.8;
    final vPoint = pFrom + vDelta * vT + vNormal * vWobble;
    vPath.lineTo(vPoint.dx, vPoint.dy);
  }
  pCanvas.drawPath(vPath, pPaint);
}

/// Texte posé sur un croquis, centré sur [pAt].
void sketchLabel(Canvas pCanvas, String pText, Offset pAt, TextStyle pStyle) {
  final vPainter = TextPainter(
    text: TextSpan(text: pText, style: pStyle),
    textDirection: TextDirection.ltr,
  )..layout();
  vPainter.paint(pCanvas, pAt - Offset(vPainter.width / 2, vPainter.height / 2));
}

/// Cote de dessin technique : ligne fine, petites flèches aux deux bouts, valeur au milieu.
void dimensionLine(
  Canvas pCanvas,
  Offset pFrom,
  Offset pTo,
  String pValue,
  Paint pPaint,
  TextStyle pStyle, {
  double pLabelShift = 12,
}) {
  pCanvas.drawLine(pFrom, pTo, pPaint);
  final vDirection = pTo - pFrom;
  final vLength = vDirection.distance;
  if (vLength < 1) {
    return;
  }
  final vUnit = vDirection / vLength;
  final vSide = Offset(-vUnit.dy, vUnit.dx);
  for (final (vTip, vBack) in [(pFrom, vUnit), (pTo, -vUnit)]) {
    pCanvas.drawLine(vTip, vTip + vBack * 7 + vSide * 3, pPaint);
    pCanvas.drawLine(vTip, vTip + vBack * 7 - vSide * 3, pPaint);
  }
  sketchLabel(pCanvas, pValue, (pFrom + pTo) / 2 + vSide * pLabelShift, pStyle);
}

/// « Comment c'est calculé » : les étapes d'un résultat, repliées sous lui.
class WhyCard extends StatelessWidget {
  const WhyCard({super.key, required this.title, required this.steps});

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.edit_note),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        children: [
          for (final (vIndex, vStep) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${vIndex + 1}. $vStep', style: vTheme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
