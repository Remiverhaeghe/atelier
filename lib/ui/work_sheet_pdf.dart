import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import 'pdf_fonts.dart';

/// Fiche de chantier : ce qu'il faut emporter sur place pour un calcul ou un geste, imprimée
/// sur une page avec des cases à cocher et de la place pour écrire.
typedef WorkSheet = ({
  String title,
  String intro,
  List<(String, String)> measures,
  List<String> results,
  List<ExtraItem> buy,
  List<String> steps,
});

/// Lignes laissées vides en bas de la fiche, pour les notes au crayon.
const workSheetNoteLines = 6;

Future<Uint8List> buildWorkSheetPdf(AppLocalizations pText, WorkSheet pSheet) async {
  final vDocument = pw.Document(title: pSheet.title, theme: await pdfTheme());
  pw.Widget vBox(String pText) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        width: 9,
        height: 9,
        margin: const pw.EdgeInsets.only(top: 2, right: 8),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      ),
      pw.Expanded(child: pw.Text(pText)),
    ],
  );
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      footer: (pContext) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          pText.sheetFooter(pContext.pageNumber, pContext.pagesCount),
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        pw.Header(level: 0, text: pSheet.title),
        if (pSheet.intro.isNotEmpty) pw.Paragraph(text: pSheet.intro),
        if (pSheet.measures.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.sheetMeasures),
          pw.TableHelper.fromTextArray(
            data: [
              for (final (vLabel, vValue) in pSheet.measures) [vLabel, vValue],
            ],
            cellAlignments: {1: pw.Alignment.centerRight},
          ),
        ],
        if (pSheet.results.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.sheetResults),
          for (final vLine in pSheet.results) pw.Bullet(text: vLine),
        ],
        if (pSheet.buy.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.sheetBuy),
          for (final vItem in pSheet.buy)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: vBox('${vItem.quantity} × ${vItem.name}'),
            ),
        ],
        if (pSheet.steps.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.sheetSteps),
          for (final vStep in pSheet.steps)
            pw.Padding(padding: const pw.EdgeInsets.only(bottom: 6), child: vBox(vStep)),
        ],
        pw.Header(level: 1, text: pText.sheetNotes),
        for (var vLine = 0; vLine < workSheetNoteLines; vLine++)
          pw.Container(
            height: 22,
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey500)),
            ),
          ),
      ],
    ),
  );

  return vDocument.save();
}

/// Bouton de barre d'application qui imprime ou enregistre la fiche en PDF.
class PrintSheetButton extends StatelessWidget {
  const PrintSheetButton({super.key, required this.sheet});

  /// Fiche construite au moment de l'appui, avec les valeurs saisies à cet instant.
  final WorkSheet Function() sheet;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return IconButton(
      tooltip: vText.sheetPrint,
      icon: const Icon(Icons.print_outlined),
      onPressed: () {
        final vSheet = sheet();
        Printing.layoutPdf(name: vSheet.title, onLayout: (_) => buildWorkSheetPdf(vText, vSheet));
      },
    );
  }
}
