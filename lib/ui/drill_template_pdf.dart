import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/drill_template.dart';
import '../logic/shelf.dart';
import '../logic/shelf_joinery.dart';
import 'pdf_fonts.dart';

/// Gabarit de perçage à l'échelle 1, la profondeur de la tablette dans la hauteur de la page.
Future<Uint8List> buildDrillTemplatePdf(
  AppLocalizations pText,
  ShelfDesign pDesign,
  JointAdvice pJoint,
) async {
  final vDocument = pw.Document(title: pText.drillTemplateTitle, theme: await pdfTheme());
  final vHoles = pJoint.joint == ShelfJoint.shelfPins
      ? pinHoles(pDesign, pJoint)
      : jointHoles(pDesign, pJoint);
  final vAcross = pJoint.joint == ShelfJoint.shelfPins ? 256 + 10.0 : pDesign.thicknessMm + 0.0;
  vDocument.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(pText.drillTemplateTitle, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(pText.drillTemplateHelp, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 4 * PdfPageFormat.mm),
          // Règle de contrôle : 100 mm imprimés doivent mesurer 100 mm
          pw.Container(
            width: 100 * PdfPageFormat.mm,
            height: 3 * PdfPageFormat.mm,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          ),
          pw.Text(pText.drillTemplateScale, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 4 * PdfPageFormat.mm),
          pw.CustomPaint(
            size: PdfPoint(vAcross * PdfPageFormat.mm, pDesign.depthMm * PdfPageFormat.mm),
            painter: (pCanvas, pSize) {
              pCanvas
                ..setLineWidth(0.5)
                ..drawRect(0, 0, pSize.x, pSize.y)
                ..strokePath();
              for (final vHole in vHoles) {
                final vX = vHole.acrossMm * PdfPageFormat.mm;
                final vY = pSize.y - vHole.alongMm * PdfPageFormat.mm;
                final vRadius = vHole.diameterMm / 2 * PdfPageFormat.mm;
                pCanvas
                  ..drawEllipse(vX, vY, vRadius, vRadius)
                  ..strokePath()
                  ..moveTo(vX - vRadius - 2, vY)
                  ..lineTo(vX + vRadius + 2, vY)
                  ..moveTo(vX, vY - vRadius - 2)
                  ..lineTo(vX, vY + vRadius + 2)
                  ..strokePath();
              }
            },
          ),
          pw.Text(pText.drillTemplateFront, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    ),
  );

  return vDocument.save();
}
