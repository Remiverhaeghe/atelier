import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/hidden_networks.dart';
import '../logic/house_book.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'behind_walls_section.dart';
import 'journal_pdf.dart';
import 'networks_section.dart';
import 'pdf_fonts.dart';

/// Dossier de la maison pour une revente : pièce par pièce, réseaux dessinés mur par mur,
/// solives, fenêtres, références posées et photos prises avant de fermer.
Future<Uint8List> buildHouseBookPdf(
  AppLocalizations pText,
  Worksite pWorksite, {
  PhotoReader pRead = readPhotoFile,
}) async {
  final vDocument = pw.Document(
    title: '${pText.bookTitle} : ${pWorksite.name}',
    theme: await pdfTheme(),
  );
  final vPages = houseBook(pWorksite);
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: '${pText.bookTitle} : ${pWorksite.name}'),
        pw.Paragraph(text: pText.bookIntro),
        if (vPages.isEmpty) pw.Paragraph(text: pText.bookEmpty),
        for (final vPage in vPages) ..._roomPage(pText, vPage, pRead),
      ],
    ),
  );

  return vDocument.save();
}

List<pw.Widget> _roomPage(AppLocalizations pText, RoomBook pPage, PhotoReader pRead) {
  final vRoom = pPage.room;
  String vCm(int pMm) => formatCentimetres(pMm);
  const vBold = pw.TextStyle(fontWeight: pw.FontWeight.bold);
  final vWallsWithRuns = {for (final vRun in vRoom.networks) vRun.wallIndex}.toList()..sort();
  final rWidgets = <pw.Widget>[
    pw.Header(level: 1, text: vRoom.name),
    if (vRoom.networks.isNotEmpty) ...[
      pw.Text(pText.netTitle, style: vBold),
      for (final vEntry in pPage.networkLengths.entries)
        pw.Bullet(
          text: pText.bookNetworkLength(
            networkLabel(pText, vEntry.key),
            formatDecimal(vEntry.value / 1000),
          ),
        ),
      for (final vWall in vWallsWithRuns)
        if (vWall < vRoom.walls.length) ...[
          pw.Text(pText.wallTitle(vWall + 1)),
          _elevation(vRoom, vWall),
          for (final vRun in vRoom.networks.where((pRun) => pRun.wallIndex == vWall))
            pw.Bullet(
              text:
                  '${networkLabel(pText, vRun.kind)} : '
                  '${pText.netRun(vCm(vRun.fromAlongMm), vCm(vRun.fromHeightMm), vCm(vRun.toAlongMm), vCm(vRun.toHeightMm))}',
            ),
        ],
    ],
    if (vRoom.behindWalls.joists.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text(pText.bookJoists, style: vBold),
      for (final vJoists in vRoom.behindWalls.joists)
        pw.Bullet(
          text:
              '${pText.behindJoistLine(joistPlaceLabel(pText, vJoists.place), vJoists.wallIndex + 1, vCm(vJoists.spacingMm))} : '
              '${pText.behindJoistAxes(vCm(vJoists.widthMm), vCm(vJoists.heightMm), joistAxes(vRoom, vJoists).map(vCm).join(', '))}',
        ),
    ],
    if (pPage.windows.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text(pText.bookWindows, style: vBold),
      for (final vWindow in pPage.windows)
        pw.Bullet(
          text: vWindow.roof
              ? pText.bookRoofWindow(vCm(vWindow.widthMm), vCm(vWindow.heightMm))
              : pText.bookWindow(
                  vWindow.wallNumber,
                  vCm(vWindow.widthMm),
                  vCm(vWindow.heightMm),
                  vCm(vWindow.sillMm),
                ),
        ),
    ],
    if (pPage.references.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text(pText.bookReferences, style: vBold),
      for (final vEntry in pPage.references)
        pw.Bullet(
          text: [
            '${vEntry.day} : ${vEntry.title}',
            if (vEntry.product.isNotEmpty) vEntry.product,
            if (vEntry.reference.isNotEmpty) pText.journalPdfReference(vEntry.reference),
          ].join(', '),
        ),
    ],
    for (final vWall in pPage.toPhotograph) pw.Paragraph(text: pText.behindToPhotograph(vWall + 1)),
    if (vRoom.behindWalls.photos.isNotEmpty) ...[
      pw.SizedBox(height: 6),
      pw.Text(pText.bookPhotos, style: vBold),
      pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final vPhoto in vRoom.behindWalls.photos)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                ?_image(pRead(vPhoto.path)),
                pw.Text(
                  [
                    '${surfaceLabel(pText, vPhoto.wallIndex)}, ${vPhoto.day}',
                    if (vPhoto.note.isNotEmpty) vPhoto.note,
                  ].join(' : '),
                ),
              ],
            ),
        ],
      ),
    ],
  ];

  return rWidgets;
}

pw.Widget? _image(Uint8List? pBytes) {
  if (pBytes == null) {
    return null;
  }
  try {
    return pw.Image(pw.MemoryImage(pBytes), height: 140, fit: pw.BoxFit.contain);
  } on Exception {
    // Image illisible : la légende suffit
    return null;
  }
}

/// Mur vu de face à l'échelle, ouvertures en pointillé et réseaux en couleur.
pw.Widget _elevation(Room pRoom, int pWallIndex) {
  final vWall = pRoom.walls[pWallIndex];
  const vWidth = 420.0;
  const vMaxHeight = 150.0;
  final vScale = math.min(
    vWidth / math.max(vWall.lengthMm, 1),
    vMaxHeight / math.max(pRoom.ceilingHeightMm, 1),
  );
  final vHeight = pRoom.ceilingHeightMm * vScale;
  PdfColor vColor(NetworkKind pKind) => PdfColor.fromInt(networkColor(pKind).toARGB32());

  final rDrawing = pw.CustomPaint(
    size: PdfPoint(vWall.lengthMm * vScale, vHeight),
    painter: (pCanvas, _) {
      pCanvas
        ..setStrokeColor(PdfColors.black)
        ..setLineWidth(1.2)
        ..drawRect(0, 0, vWall.lengthMm * vScale, vHeight)
        ..strokePath();
      for (final vOpening in vWall.openings) {
        pCanvas
          ..setStrokeColor(PdfColors.grey)
          ..setLineWidth(0.6)
          ..setLineDashPattern([3, 2])
          ..drawRect(
            vOpening.offsetMm * vScale,
            vOpening.sill * vScale,
            vOpening.widthMm * vScale,
            vOpening.height * vScale,
          )
          ..strokePath()
          ..setLineDashPattern();
      }
      for (final vRun in pRoom.networks.where((pRun) => pRun.wallIndex == pWallIndex)) {
        pCanvas
          ..setStrokeColor(vColor(vRun.kind))
          ..setLineWidth(2.5)
          ..moveTo(vRun.fromAlongMm * vScale, vRun.fromHeightMm * vScale)
          ..lineTo(vRun.toAlongMm * vScale, vRun.toHeightMm * vScale)
          ..strokePath();
      }
    },
  );

  return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: rDrawing);
}
