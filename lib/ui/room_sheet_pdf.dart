import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/fixtures.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/slope.dart';
import '../logic/units.dart';
import '../storage/photo_store.dart';
import 'pdf_fonts.dart';
import 'room_measure_picker.dart' show lengthText;
import 'room_sheet_climate.dart';

/// Fiche d'une pièce à emporter sur le chantier : plan coté, murs, hauteur, rampants, reprises avec
/// leur photo et ses cercles, puis l'humidité des derniers jours suivis. [pPhotos] lit une photo
/// gardée (le stockage de l'appli par défaut, une autre source dans les tests).
Future<Uint8List> buildRoomSheetPdf(
  AppLocalizations pText,
  Room pRoom, {
  Uint8List? Function(String pPath) pPhotos = readPhoto,
  FieldUnit pUnit = FieldUnit.cm,
}) async {
  final vDocument = pw.Document(title: pText.roomSheetTitle(pRoom.name), theme: await pdfTheme());
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.roomSheetTitle(pRoom.name)),
        ...roomSheetGeometry(pText, pRoom, pUnit: pUnit),
        pw.Header(level: 1, text: pText.roomSheetTouchUps),
        if (pRoom.touchUps.isEmpty) pw.Paragraph(text: pText.roomSheetNoTouchUps),
        for (final (vIndex, vTouchUp) in pRoom.touchUps.indexed)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(vTouchUp.done ? '[x] ' : '[  ] '),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${vIndex + 1}. ${vTouchUp.label}',
                        style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        pText.roomSheetPasses(
                          vTouchUp.donePasses.toString(),
                          vTouchUp.passes.toString(),
                        ),
                      ),
                      if (vTouchUp.note.isNotEmpty) pw.Text(vTouchUp.note),
                      if (vTouchUp.toBuy.isNotEmpty) pw.Text(pText.roomSheetToBuy(vTouchUp.toBuy)),
                      if (_photo(vTouchUp.photoPath, vTouchUp.photoMarks, pPhotos)
                          case final vPhoto?)
                        pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: vPhoto),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ...climateSheetSection(pText, pRoom.climate),
      ],
    ),
  );

  return vDocument.save();
}

/// Plan coté, hauteur, surface, rampants et tableau des murs avec leurs ouvertures : ce qui
/// décrit la pièce, repris par la fiche de la pièce et la fiche à remettre à un artisan.
List<pw.Widget> roomSheetGeometry(
  AppLocalizations pText,
  Room pRoom, {
  FieldUnit pUnit = FieldUnit.cm,
}) {
  String vLength(int pMm) => lengthText(pText, pMm, pUnit);
  final vCount = pRoom.walls.length;
  String vCorner(int pIndex) => String.fromCharCode(65 + pIndex % math.max(vCount, 1));
  String vKind(OpeningKind pKind) => switch (pKind) {
    OpeningKind.door => pText.openingDoor,
    OpeningKind.passage => pText.openingPassage,
    OpeningKind.window => pText.openingWindow,
  };
  String vSlope(Slope pSlope) =>
      pText.roomSheetSlope(pSlope.wallIndex + 1, vLength(pSlope.lowMm), vLength(pSlope.runMm));

  return [
    if (vCount >= 3) ...[
      pw.Paragraph(text: pText.roomSheetHelp),
      pw.Center(child: _plan(pRoom)),
      pw.SizedBox(height: 8),
    ],
    pw.Paragraph(text: pText.roomSheetHeight(vLength(pRoom.ceilingHeightMm))),
    if (vCount >= 3)
      pw.Paragraph(
        text: pText.roomSheetArea(
          formatSquareMetres(floorAreaM2(pRoom)),
          vLength(perimeterMm(pRoom)),
        ),
      ),
    for (final vSlopeOf in [pRoom.slope, pRoom.slope2])
      if (vSlopeOf != null) pw.Paragraph(text: vSlope(vSlopeOf)),
    if (vCount > 0) ...[
      pw.Header(level: 1, text: pText.roomSheetWalls),
      pw.TableHelper.fromTextArray(
        headers: [
          pText.roomSheetWall,
          pText.roomSheetFromTo,
          pText.cutListLength,
          pText.roomSheetAngle,
          pText.roomSheetOpenings,
        ],
        data: [
          for (final (vIndex, vWall) in pRoom.walls.indexed)
            [
              '${vIndex + 1}',
              '${vCorner(vIndex)} → ${vCorner(vIndex + 1)}',
              vWall.deduced
                  ? '${vLength(vWall.lengthMm)} (${pText.roomSheetDeduced})'
                  : vLength(vWall.lengthMm),
              '${formatDecimal(vWall.angleToNextDeg)}°',
              [
                for (final vOpening in vWall.openings)
                  pText.sketchOpening(
                    vKind(vOpening.kind),
                    vLength(vOpening.widthMm),
                    vLength(vOpening.offsetMm),
                    vCorner(vIndex),
                  ),
              ].join('\n'),
            ],
        ],
      ),
    ],
  ];
}

/// Largeur d'une photo de reprise sur la fiche, en points.
const sheetPhotoWidth = 220.0;

/// Photo d'une reprise avec ses cercles, ou null sans photo lisible : une photo perdue ou
/// abîmée ne bloque pas la fiche.
pw.Widget? _photo(
  String? pPath,
  List<({double x, double y})> pMarks,
  Uint8List? Function(String pPath) pPhotos,
) {
  final vBytes = pPath == null ? null : pPhotos(pPath);
  if (vBytes == null || vBytes.isEmpty) {
    return null;
  }
  final pw.MemoryImage vImage;
  try {
    vImage = pw.MemoryImage(vBytes);
  } on Object {
    return null;
  }
  final vRatio = (vImage.width ?? 4) / math.max(vImage.height ?? 3, 1);
  final vHeight = sheetPhotoWidth / vRatio;
  const vRing = 16.0;

  return pw.SizedBox(
    width: sheetPhotoWidth,
    height: vHeight,
    child: pw.Stack(
      children: [
        pw.Image(vImage, width: sheetPhotoWidth, height: vHeight, fit: pw.BoxFit.fill),
        for (final vMark in pMarks)
          pw.Positioned(
            left: vMark.x * sheetPhotoWidth - vRing / 2,
            top: vMark.y * vHeight - vRing / 2,
            child: pw.Container(
              width: vRing,
              height: vRing,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.red, width: 2),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Plan à l'échelle : murs mesurés en trait plein, déduits en pointillés, ouvertures laissées
/// ouvertes, numéros des murs, lettres des coins et repères des reprises.
pw.Widget _plan(Room pRoom) {
  const vWidth = 480.0;
  const vHeight = 300.0;
  const vMargin = 24.0;
  final vPoints = outline(pRoom);
  final vXs = vPoints.map((pPoint) => pPoint.x);
  final vYs = vPoints.map((pPoint) => pPoint.y);
  final vMinX = vXs.reduce(math.min);
  final vMinY = vYs.reduce(math.min);
  final vSpanX = math.max(vXs.reduce(math.max) - vMinX, 1.0);
  final vSpanY = math.max(vYs.reduce(math.max) - vMinY, 1.0);
  final vScale = math.min((vWidth - 2 * vMargin) / vSpanX, (vHeight - 2 * vMargin) / vSpanY);
  final vLeft = (vWidth - vSpanX * vScale) / 2;
  final vBottom = (vHeight - vSpanY * vScale) / 2;
  // Le PDF compte les y vers le haut, comme le plan : pas de retournement
  PdfPoint vAt(double pX, double pY) =>
      PdfPoint(vLeft + (pX - vMinX) * vScale, vBottom + (pY - vMinY) * vScale);
  final vScreen = [for (final vPoint in vPoints) vAt(vPoint.x, vPoint.y)];
  final vCentre = PdfPoint(
    vScreen.map((pPoint) => pPoint.x).reduce((pA, pB) => pA + pB) / vScreen.length,
    vScreen.map((pPoint) => pPoint.y).reduce((pA, pB) => pA + pB) / vScreen.length,
  );
  PdfPoint vPushed(PdfPoint pPoint, double pDistance) {
    final vDx = pPoint.x - vCentre.x;
    final vDy = pPoint.y - vCentre.y;
    final vLength = math.max(math.sqrt(vDx * vDx + vDy * vDy), 1.0);

    return PdfPoint(pPoint.x + vDx / vLength * pDistance, pPoint.y + vDy / vLength * pDistance);
  }

  pw.Widget vLabel(PdfPoint pAt, String pText, {bool pCircled = false}) => pw.Positioned(
    left: pAt.x - 9,
    bottom: pAt.y - 7,
    child: pw.Container(
      width: 18,
      height: 14,
      alignment: pw.Alignment.center,
      decoration: pCircled
          ? pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(width: 0.8),
              borderRadius: pw.BorderRadius.circular(7),
            )
          : null,
      child: pw.Text(pText, style: const pw.TextStyle(fontSize: 9)),
    ),
  );

  final vWalls = pRoom.walls.length;
  final vEdges = math.min(vScreen.length - 1, vWalls);

  return pw.SizedBox(
    width: vWidth,
    height: vHeight,
    child: pw.Stack(
      children: [
        pw.CustomPaint(
          size: const PdfPoint(vWidth, vHeight),
          painter: (pCanvas, _) {
            for (var vIndex = 0; vIndex < vEdges; vIndex++) {
              final vFrom = vScreen[vIndex];
              final vTo = vScreen[vIndex + 1];
              pCanvas
                ..setStrokeColor(PdfColors.black)
                ..setLineWidth(1.6);
              if (pRoom.walls[vIndex].deduced) {
                pCanvas.setLineDashPattern([4, 3]);
              }
              pCanvas
                ..moveTo(vFrom.x, vFrom.y)
                ..lineTo(vTo.x, vTo.y)
                ..strokePath()
                ..setLineDashPattern();
              final vWall = pRoom.walls[vIndex];
              if (vWall.lengthMm == 0) {
                continue;
              }
              final vStepX = (vTo.x - vFrom.x) / vWall.lengthMm;
              final vStepY = (vTo.y - vFrom.y) / vWall.lengthMm;
              for (final vOpening in vWall.openings) {
                final vStartX = vFrom.x + vStepX * vOpening.offsetMm;
                final vStartY = vFrom.y + vStepY * vOpening.offsetMm;
                final vEndX = vStartX + vStepX * vOpening.widthMm;
                final vEndY = vStartY + vStepY * vOpening.widthMm;
                pCanvas
                  ..setStrokeColor(PdfColors.white)
                  ..setLineWidth(3.5)
                  ..moveTo(vStartX, vStartY)
                  ..lineTo(vEndX, vEndY)
                  ..strokePath()
                  ..setStrokeColor(PdfColors.black)
                  ..setLineWidth(0.6);
                if (vOpening.kind == OpeningKind.window) {
                  pCanvas
                    ..moveTo(vStartX, vStartY)
                    ..lineTo(vEndX, vEndY)
                    ..strokePath();
                }
              }
            }
            pCanvas
              ..setStrokeColor(PdfColors.grey600)
              ..setLineWidth(0.6)
              ..setLineDashPattern([2, 2]);
            for (final vFixture in pRoom.fixtures.where((pFixture) => hasArea(pFixture.kind))) {
              final vOutline = [
                for (final (vX, vY) in vFixture.outlineMm()) vAt(vX.toDouble(), vY.toDouble()),
              ];
              pCanvas.moveTo(vOutline.first.x, vOutline.first.y);
              for (final vPoint in vOutline.skip(1)) {
                pCanvas.lineTo(vPoint.x, vPoint.y);
              }
              pCanvas
                ..closePath()
                ..strokePath();
            }
            pCanvas.setLineDashPattern();
          },
        ),
        for (var vIndex = 0; vIndex < vEdges; vIndex++) ...[
          vLabel(
            vPushed(
              PdfPoint(
                (vScreen[vIndex].x + vScreen[vIndex + 1].x) / 2,
                (vScreen[vIndex].y + vScreen[vIndex + 1].y) / 2,
              ),
              -14,
            ),
            '${vIndex + 1}',
            pCircled: true,
          ),
          vLabel(vPushed(vScreen[vIndex], 11), String.fromCharCode(65 + vIndex)),
        ],
        for (final (vIndex, vTouchUp) in pRoom.touchUps.indexed)
          if (vTouchUp.hasMarker)
            vLabel(
              vAt(vTouchUp.markerXMm!.toDouble(), vTouchUp.markerYMm!.toDouble()),
              '${vIndex + 1}',
              pCircled: true,
            ),
      ],
    ),
  );
}
