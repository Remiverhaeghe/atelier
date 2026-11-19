import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/memories.dart';
import '../logic/worksite.dart';
import 'journal_pdf.dart';
import 'pdf_fonts.dart';

/// Couleurs du carnet : papier crème, quadrillage bleu pâle, encre de crayon.
const _aPaper = PdfColor.fromInt(0xFFFBF8F1);
const _aGrid = PdfColor.fromInt(0xFFDCE6F0);
const _aInk = PdfColor.fromInt(0xFF2F3A4A);

/// Police manuscrite des légendes ; null sans les assets (tests), le PDF garde la police de base.
Future<pw.Font?> _handFont() async {
  try {
    return pw.Font.ttf(await rootBundle.load('assets/fonts/Caveat-Regular.ttf'));
  } on FlutterError {
    return null;
  }
}

/// Souvenirs du chantier en PDF façon carnet : une page par entrée, l'avant et l'après côte à
/// côte sur papier quadrillé, légendés à la main.
Future<Uint8List> buildMemoriesPdf(
  AppLocalizations pText,
  Worksite pWorksite, {
  PhotoReader pRead = readPhotoFile,
}) async {
  final vDocument = pw.Document(
    title: '${pText.memoriesTitle} : ${pWorksite.name}',
    theme: await pdfTheme(),
  );
  final vHand = await _handFont();
  final vCaption = pw.TextStyle(font: vHand, fontSize: 18, color: _aInk);
  final vTitle = pw.TextStyle(font: vHand, fontSize: 30, color: _aInk);
  String vRoom(String pId) =>
      pWorksite.rooms.where((pRoom) => pRoom.id == pId).firstOrNull?.name ?? '';

  pw.Widget vPhoto(String? pPath, String pLabel) {
    final vBytes = pPath == null ? null : pRead(pPath);
    pw.Widget vImage;
    try {
      vImage = vBytes == null
          ? pw.Center(child: pw.Text(pText.memoriesMissingPhoto))
          : pw.Image(pw.MemoryImage(vBytes), fit: pw.BoxFit.cover);
    } on Exception {
      vImage = pw.Center(child: pw.Text(pText.memoriesMissingPhoto));
    }

    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(pLabel, style: vCaption),
          pw.Container(
            height: 260,
            padding: const pw.EdgeInsets.all(6),
            // Cadre blanc de photo collée dans le carnet
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _aGrid, width: 1),
            ),
            child: vImage,
          ),
        ],
      ),
    );
  }

  final vPage = pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    buildBackground: (_) => pw.FullPage(
      ignoreMargins: true,
      child: pw.CustomPaint(
        size: const PdfPoint(double.infinity, double.infinity),
        painter: (pCanvas, pSize) {
          pCanvas
            ..setColor(_aPaper)
            ..drawRect(0, 0, pSize.x, pSize.y)
            ..fillPath()
            ..setStrokeColor(_aGrid)
            ..setLineWidth(0.5);
          for (var vX = 0.0; vX < pSize.x; vX += 14) {
            pCanvas
              ..drawLine(vX, 0, vX, pSize.y)
              ..strokePath();
          }
          for (var vY = 0.0; vY < pSize.y; vY += 14) {
            pCanvas
              ..drawLine(0, vY, pSize.x, vY)
              ..strokePath();
          }
        },
      ),
    ),
  );
  final vEntries = memoryEntries(pWorksite.journal);
  final vSpan = memorySpan(pWorksite.journal);

  vDocument.addPage(
    pw.Page(
      pageTheme: vPage,
      build: (_) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(pText.memoriesTitle, style: vTitle),
            pw.SizedBox(height: 8),
            pw.Text(pWorksite.name, style: vCaption),
            if (vSpan != null)
              pw.Text(pText.memoriesSpan(vSpan.first, vSpan.last), style: vCaption),
          ],
        ),
      ),
    ),
  );
  for (final vEntry in vEntries) {
    vDocument.addPage(
      pw.Page(
        pageTheme: vPage,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(vEntry.title, style: vTitle),
            pw.Text('${vRoom(vEntry.roomId)} · ${vEntry.day}', style: vCaption),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (vEntry.beforePath != null) ...[
                  vPhoto(vEntry.beforePath, pText.memoriesBefore),
                  pw.SizedBox(width: 12),
                ],
                vPhoto(vEntry.photoPath, pText.memoriesAfter),
              ],
            ),
            if (vEntry.note.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text(vEntry.note, style: vCaption),
            ],
          ],
        ),
      ),
    );
  }

  return vDocument.save();
}
