import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/baseboard.dart';
import '../logic/geometry.dart';
import '../logic/laying_plan.dart';
import '../logic/parquet.dart';
import '../logic/room.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'baseboard_view.dart';
import 'shopping_texts.dart';

/// Fiche du chantier à imprimer : liste de courses, puis plan, parquet et plinthes de chaque pièce.
Future<Uint8List> buildWorksitePdf(AppLocalizations pText, Worksite pWorksite) {
  final vDocument = pw.Document(title: pWorksite.name);
  final vLines = shoppingList(pWorksite);
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pWorksite.name),
        pw.Header(level: 1, text: pText.shoppingTitle),
        for (final vLine in vLines)
          pw.Bullet(text: '${itemLabel(pText, vLine.item)} : ${lineDetail(pText, vLine)}'),
        pw.Paragraph(text: pText.budgetTotal(formatEuros(budgetTotal(vLines)))),
        if (budgetIncomplete(vLines)) pw.Paragraph(text: pText.budgetIncomplete),
        for (final vRoom in pWorksite.rooms) ..._roomSection(pText, vRoom),
      ],
    ),
  );

  return vDocument.save();
}

List<pw.Widget> _roomSection(AppLocalizations pText, Room pRoom) {
  final vEstimate = estimateParquet(pRoom, pRoom.parquet);
  final vPlan = planLaying(pRoom, pRoom.parquet);
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  final rWidgets = <pw.Widget>[
    pw.Header(level: 1, text: pText.pdfRoom(pRoom.name)),
    if (pRoom.walls.isNotEmpty) _plan(pRoom),
    pw.Paragraph(
      text: pText.resultArea(
        formatSquareMetres(vEstimate.floorAreaM2),
        formatSquareMetres(vEstimate.areaWithWasteM2),
      ),
    ),
    pw.Header(level: 2, text: pText.pdfParquet),
    pw.Paragraph(text: pText.resultPacks(vEstimate.packs)),
    if (vPlan != null)
      for (final vRow in vPlan.rows)
        pw.Bullet(
          text:
              '${pText.layingRowTitle(vRow.number, formatCentimetres(vRow.widthMm))} : '
              '${vRow.runs.map((pRun) => pRun.pieces.map(formatCentimetres).join(' + ')).join(' / ')} cm',
        ),
    pw.Header(level: 2, text: pText.pdfBaseboard),
    for (final vPiece in vPieces)
      pw.Bullet(
        text:
            '${pText.pieceTitle(vPiece.wallNumber, formatCentimetres(vPiece.lengthMm))} : '
            '${pText.pieceCuts(cutLabel(pText, vPiece.startCut), cutLabel(pText, vPiece.endCut))}',
      ),
  ];

  return rWidgets;
}

/// Contour de la pièce à l'échelle, murs numérotés.
pw.Widget _plan(Room pRoom) {
  final vPoints = outline(pRoom);
  final vMinX = vPoints.map((pPoint) => pPoint.x).reduce(math.min);
  final vMaxX = vPoints.map((pPoint) => pPoint.x).reduce(math.max);
  final vMinY = vPoints.map((pPoint) => pPoint.y).reduce(math.min);
  final vMaxY = vPoints.map((pPoint) => pPoint.y).reduce(math.max);
  const vWidth = 400.0;
  const vHeight = 260.0;
  const vMargin = 16.0;
  final vScale = math.min(
    (vWidth - 2 * vMargin) / math.max(vMaxX - vMinX, 1),
    (vHeight - 2 * vMargin) / math.max(vMaxY - vMinY, 1),
  );
  PdfPoint vToPage(PlanPoint pPoint) =>
      PdfPoint(vMargin + (pPoint.x - vMinX) * vScale, vMargin + (pPoint.y - vMinY) * vScale);

  final rPlan = pw.Stack(
    children: [
      pw.CustomPaint(
        size: const PdfPoint(vWidth, vHeight),
        painter: (pCanvas, _) {
          final vStart = vToPage(vPoints.first);
          pCanvas.moveTo(vStart.x, vStart.y);
          for (final vPoint in vPoints.skip(1)) {
            final vPage = vToPage(vPoint);
            pCanvas.lineTo(vPage.x, vPage.y);
          }
          pCanvas
            ..setLineWidth(2)
            ..strokePath();
        },
      ),
      for (var vIndex = 0; vIndex < pRoom.walls.length; vIndex++)
        pw.Positioned(
          left: (vToPage(vPoints[vIndex]).x + vToPage(vPoints[vIndex + 1]).x) / 2 - 4,
          bottom: (vToPage(vPoints[vIndex]).y + vToPage(vPoints[vIndex + 1]).y) / 2 + 2,
          child: pw.Text('${vIndex + 1}'),
        ),
    ],
  );

  return rPlan;
}
