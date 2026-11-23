import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/room_shopping.dart';
import '../logic/worksite.dart';
import 'pdf_fonts.dart';
import 'shopping_texts.dart';

/// Devis estimatif des fournitures, pièce par pièce, d'après les prix saisis : à garder pour le
/// budget ou à montrer à une banque. Estimation, pas un engagement de prix.
Future<Uint8List> buildEstimatePdf(
  AppLocalizations pText,
  Worksite pWorksite, {
  required DateTime pToday,
}) async {
  final vDocument = pw.Document(
    title: pText.estimateTitle(pWorksite.name),
    theme: await pdfTheme(),
  );
  final vRooms = shoppingByRoom(pWorksite);
  final vTotal = vRooms.fold<double>(0, (pSum, pItem) => pSum + pItem.cost);
  final vIncomplete = vRooms.any((pItem) => pItem.incomplete);
  const vBold = pw.TextStyle(fontWeight: pw.FontWeight.bold);

  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.estimateTitle(pWorksite.name)),
        pw.Paragraph(text: pText.estimateIntro(goalDate(pToday))),
        for (final vRoom in vRooms) ...[
          pw.Header(level: 1, text: vRoom.room.name),
          pw.TableHelper.fromTextArray(
            headers: [pText.estimateItem, pText.estimateQuantity, pText.estimateAmount],
            data: [
              for (final vLine in vRoom.lines)
                [
                  itemLabel(pText, vLine.item),
                  '${vLine.quantity}',
                  vLine.total == null ? pText.estimateNoPrice : formatEuros(vLine.total!),
                ],
            ],
          ),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(pText.estimateRoomTotal(formatEuros(vRoom.cost)), style: vBold),
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Text(pText.estimateTotal(formatEuros(vTotal)), style: vBold),
        if (vIncomplete) pw.Paragraph(text: pText.budgetIncomplete),
        pw.Paragraph(text: pText.estimateFromPrices),
      ],
    ),
  );

  return vDocument.save();
}
