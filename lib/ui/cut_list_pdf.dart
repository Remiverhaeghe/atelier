import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/cut_list.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'baseboard_view.dart';

/// Liste de coupes d'une pièce à imprimer : une case à cocher par longueur, la plus longue d'abord.
Future<Uint8List> buildCutListPdf(AppLocalizations pText, Room pRoom) {
  final vDocument = pw.Document(title: pText.roomCutsTitle(pRoom.name));
  final vBaseboard = baseboardCutList(pRoom);
  final vPlanks = plankCutList(pRoom);
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.roomCutsTitle(pRoom.name)),
        pw.Paragraph(text: pText.cutListHelp),
        if (vBaseboard.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.pdfBaseboard),
          _table(pText, vBaseboard, pText.cutListWalls, (pLine) {
            return '${cutLabel(pText, pLine.startCut!)} / ${cutLabel(pText, pLine.endCut!)}';
          }),
        ],
        if (vPlanks.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.pdfParquet),
          _table(pText, vPlanks, pText.cutListRows, (_) => pText.cutSquare),
        ],
        if (vBaseboard.isEmpty && vPlanks.isEmpty) pw.Paragraph(text: pText.cutListEmpty),
      ],
    ),
  );

  return vDocument.save();
}

pw.Widget _table(
  AppLocalizations pText,
  List<CutLine> pLines,
  String Function(String) pPlaces,
  String Function(CutLine) pCuts,
) => pw.TableHelper.fromTextArray(
  headers: ['', pText.cutListLength, pText.cutListCount, pText.cutListCuts, pText.cutListWhere],
  data: [
    for (final vLine in pLines)
      [
        '[  ]',
        '${formatCentimetres(vLine.lengthMm)} cm',
        '× ${vLine.count}',
        pCuts(vLine),
        pPlaces(vLine.places.join(', ')),
      ],
  ],
);
