import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/goals.dart';
import '../logic/paint.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'journal_pdf.dart';
import 'pdf_fonts.dart';

/// Plan d'une pièce dessiné dans un cadre de [pWidth] sur [pHeight] points.
pw.Widget _plan(Room pRoom, double pWidth, double pHeight) {
  final vPoints = outline(pRoom);

  return pw.SizedBox(
    width: pWidth,
    height: pHeight,
    child: pw.CustomPaint(
      size: PdfPoint(pWidth, pHeight),
      painter: (pCanvas, pSize) {
        if (vPoints.length < 3) {
          return;
        }
        final vXs = vPoints.map((pPoint) => pPoint.x);
        final vYs = vPoints.map((pPoint) => pPoint.y);
        final vMinX = vXs.reduce((pA, pB) => pA < pB ? pA : pB);
        final vMinY = vYs.reduce((pA, pB) => pA < pB ? pA : pB);
        final vSpanX = vXs.reduce((pA, pB) => pA > pB ? pA : pB) - vMinX;
        final vSpanY = vYs.reduce((pA, pB) => pA > pB ? pA : pB) - vMinY;
        final vScale = [
          pSize.x / (vSpanX <= 0 ? 1 : vSpanX),
          pSize.y / (vSpanY <= 0 ? 1 : vSpanY),
        ].reduce((pA, pB) => pA < pB ? pA : pB);
        pCanvas
          ..setStrokeColor(PdfColors.grey800)
          ..setLineWidth(1.5)
          ..moveTo((vPoints.first.x - vMinX) * vScale, (vPoints.first.y - vMinY) * vScale);
        for (final vPoint in vPoints.skip(1)) {
          pCanvas.lineTo((vPoint.x - vMinX) * vScale, (vPoint.y - vMinY) * vScale);
        }
        pCanvas
          ..closePath()
          ..strokePath();
      },
    ),
  );
}

/// Mesures d'une pièce utiles à un artisan pour chiffrer.
List<String> _facts(AppLocalizations pText, Room pRoom) {
  final vAreas = paintAreas(pRoom);

  return [
    pText.quoteFloor(formatSquareMetres(floorAreaM2(pRoom))),
    pText.quoteWalls(formatSquareMetres(vAreas.wallsM2)),
    pText.quoteCeiling(formatSquareMetres(vAreas.ceilingM2)),
    pText.quoteHeight(formatCentimetres(pRoom.ceilingHeightMm)),
    pText.quotePerimeter(formatCentimetres(perimeterMm(pRoom))),
  ];
}

/// Dossier à envoyer à des artisans pour avoir des devis comparables : pièce par pièce,
/// surfaces, plan, travaux demandés et photos.
Future<Uint8List> buildQuotePdf(
  AppLocalizations pText,
  Worksite pWorksite, {
  required DateTime pToday,
  PhotoReader? pRead,
}) async {
  final vDocument = pw.Document(
    title: pText.quoteTitle(pWorksite.name),
    theme: await pdfTheme(),
  );
  pw.Widget? vPhoto(String? pPath) {
    final vBytes = pPath == null || pRead == null ? null : pRead(pPath);
    if (vBytes == null) {
      return null;
    }
    try {
      return pw.Image(pw.MemoryImage(vBytes), height: 120, fit: pw.BoxFit.contain);
    } on Exception {
      return null;
    }
  }

  const vBold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.quoteTitle(pWorksite.name)),
        pw.Paragraph(text: pText.quoteIntro(goalDate(pToday))),
        for (final vRoom in pWorksite.rooms.where((pRoom) => pRoom.walls.length >= 3)) ...[
          pw.Header(level: 1, text: vRoom.name),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _plan(vRoom, 160, 120),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [for (final vLine in _facts(pText, vRoom)) pw.Text(vLine)],
                ),
              ),
            ],
          ),
          if (vRoom.touchUps.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(pText.quoteWork, style: vBold),
            for (final vTouchUp in vRoom.touchUps)
              pw.Bullet(
                text: [vTouchUp.label, if (vTouchUp.note.isNotEmpty) vTouchUp.note].join(' : '),
              ),
            if ([for (final vTouchUp in vRoom.touchUps) ?vPhoto(vTouchUp.photoPath)]
                case final vImages when vImages.isNotEmpty)
              pw.Wrap(spacing: 8, runSpacing: 8, children: vImages),
          ],
        ],
        pw.SizedBox(height: 16),
        pw.Text(pText.quoteAsk, style: vBold),
        pw.Paragraph(text: pText.quoteAskList),
      ],
    ),
  );

  return vDocument.save();
}
