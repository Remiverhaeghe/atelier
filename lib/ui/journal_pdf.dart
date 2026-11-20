import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/journal.dart';
import '../logic/worksite.dart';
import '../storage/photo_store.dart';
import 'pdf_fonts.dart';
import 'shopping_texts.dart';

/// Lecture d'une photo du carnet ; null si le fichier a disparu du téléphone.
typedef PhotoReader = Uint8List? Function(String pPath);

/// Lecture d'une photo du téléphone ; null si le fichier n'existe plus.
Uint8List? readPhotoFile(String pPath) => readPhoto(pPath);

/// Carnet de la maison à imprimer ou à joindre à une vente : pièce par pièce, produits,
/// références, coûts, photos d'avant et d'après, factures.
Future<Uint8List> buildJournalPdf(
  AppLocalizations pText,
  Worksite pWorksite, {
  PhotoReader pRead = readPhotoFile,
}) async {
  final vDocument = pw.Document(
    title: '${pText.journalTitle} : ${pWorksite.name}',
    theme: await pdfTheme(),
  );
  pw.Widget? vPhoto(String? pPath) {
    final vBytes = pPath == null ? null : pRead(pPath);
    if (vBytes == null) {
      return null;
    }
    try {
      return pw.Image(pw.MemoryImage(vBytes), height: 150, fit: pw.BoxFit.contain);
    } on Exception {
      // Image illisible : on garde le texte de l'entrée
      return null;
    }
  }

  List<pw.Widget> vImages(JournalEntry pEntry) => [
    for (final vPath in [pEntry.beforePath, pEntry.photoPath, pEntry.invoicePath]) ?vPhoto(vPath),
  ];
  const vBold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: '${pText.journalTitle} : ${pWorksite.name}'),
        for (final vRoom in pWorksite.rooms)
          if (journalOf(pWorksite.journal, pRoomId: vRoom.id) case final vEntries
              when vEntries.isNotEmpty) ...[
            pw.Header(level: 1, text: vRoom.name),
            for (final vEntry in vEntries) ...[
              pw.Text('${vEntry.day} : ${vEntry.title}', style: vBold),
              if (vEntry.product.isNotEmpty) pw.Text(pText.journalPdfProduct(vEntry.product)),
              if (vEntry.reference.isNotEmpty) pw.Text(pText.journalPdfReference(vEntry.reference)),
              if (vEntry.cost != null) pw.Text('${formatEuros(vEntry.cost!)} €'),
              if (vEntry.note.isNotEmpty) pw.Text(vEntry.note),
              if (vImages(vEntry) case final vList when vList.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Wrap(spacing: 8, runSpacing: 8, children: vList),
                ),
              pw.SizedBox(height: 10),
            ],
          ],
        if (pWorksite.journal.isEmpty) pw.Paragraph(text: pText.journalEmpty),
        if (journalCost(pWorksite.journal) > 0)
          pw.Paragraph(text: pText.journalCost(formatEuros(journalCost(pWorksite.journal)))),
      ],
    ),
  );

  return vDocument.save();
}
