import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/baseboard.dart';
import '../logic/baseboard_bars.dart';
import '../logic/cut_list.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'baseboard_view.dart';
import 'pdf_fonts.dart';
import 'room_measure_picker.dart' show lengthInUnit, lengthText, unitName;

/// Liste de coupes d'une pièce à imprimer : une case à cocher par longueur, la plus longue d'abord.
Future<Uint8List> buildCutListPdf(
  AppLocalizations pText,
  Room pRoom, {
  FieldUnit pUnit = FieldUnit.cm,
}) async {
  final vDocument = pw.Document(title: pText.roomCutsTitle(pRoom.name), theme: await pdfTheme());
  final vBaseboard = baseboardCutList(pRoom);
  final vPieces = baseboardPieces(pRoom, pRoom.baseboard);
  final vBars = planBaseboardBars(vPieces, pRoom.baseboard);
  final vPlanks = plankCutList(pRoom);
  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.roomCutsTitle(pRoom.name)),
        pw.Paragraph(text: pText.cutListHelp),
        if (vBaseboard.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.pdfBaseboard),
          _table(pText, vBaseboard, pText.cutListWalls, pUnit, (pLine) {
            return '${cutLabel(pText, pLine.startCut!)} / ${cutLabel(pText, pLine.endCut!)}';
          }),
          pw.Header(level: 2, text: pText.barsTitle),
          for (var vBar = 0; vBar < vBars.bars.length; vBar++)
            pw.Bullet(
              text:
                  '${pText.barLine(vBar + 1, '${[for (final vIndex in vBars.bars[vBar].pieceIndexes) lengthInUnit(vPieces[vIndex].lengthMm, pUnit)].join(' + ')} ${unitName(pText, pUnit)}')}'
                  ' (${offcutLabel(pText, vBars.bars[vBar].offcutMm(vBars.kerfMm), pUnit)})',
            ),
        ],
        if (vPlanks.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.pdfParquet),
          _table(pText, vPlanks, pText.cutListRows, pUnit, (_) => pText.cutSquare),
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
  FieldUnit pUnit,
  String Function(CutLine) pCuts,
) => pw.TableHelper.fromTextArray(
  headers: ['', pText.cutListLength, pText.cutListCount, pText.cutListCuts, pText.cutListWhere],
  data: [
    for (final vLine in pLines)
      [
        '[  ]',
        lengthText(pText, vLine.lengthMm, pUnit),
        '× ${vLine.count}',
        pCuts(vLine),
        pPlaces(vLine.places.join(', ')),
      ],
  ],
);
