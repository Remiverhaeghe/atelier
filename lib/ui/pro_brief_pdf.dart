import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/fixtures.dart';
import '../logic/journal.dart';
import '../logic/room.dart';
import '../storage/photo_store.dart';
import 'fixtures_section.dart' show fixtureLabel;
import 'pdf_fonts.dart';
import 'room_sheet_pdf.dart';

/// Photos jointes à la fiche : assez pour montrer l'état de la pièce, pas pour alourdir le PDF.
const proBriefMaxPhotos = 4;

/// Fiche à remettre à un artisan pour un travail qu'on ne fait pas soi-même : les mesures de la
/// pièce, ce qu'elle contient, les contraintes à signaler et des photos. [pTrade] est le nom du
/// métier, [pConstraints] le texte libre saisi (accès, coupure d'eau ou de courant, horaires).
Future<Uint8List> buildProBriefPdf(
  AppLocalizations pText,
  Room pRoom, {
  required String pTrade,
  String pConstraints = '',
  List<JournalEntry> pJournal = const [],
  Uint8List? Function(String pPath) pPhotos = readPhoto,
}) async {
  final vDocument = pw.Document(title: pText.proBriefTitle(pRoom.name), theme: await pdfTheme());
  final vPhotos = <pw.Widget>[];
  for (final vEntry in pJournal) {
    for (final vPath in [vEntry.beforePath, vEntry.photoPath].nonNulls) {
      final vBytes = pPhotos(vPath);
      if (vBytes == null || vBytes.isEmpty || vPhotos.length >= proBriefMaxPhotos) {
        continue;
      }
      try {
        vPhotos.add(
          pw.Image(pw.MemoryImage(vBytes), width: 240, height: 180, fit: pw.BoxFit.contain),
        );
      } on Object {
        // Photo abîmée : la fiche se fait sans elle
      }
    }
  }
  final vFixtures = <FixtureKind, int>{};
  for (final vFixture in pRoom.fixtures) {
    vFixtures[vFixture.kind] = (vFixtures[vFixture.kind] ?? 0) + 1;
  }

  vDocument.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: pText.proBriefTitle(pRoom.name)),
        pw.Paragraph(text: pText.proBriefTrade(pTrade)),
        pw.Header(level: 1, text: pText.proBriefConstraints),
        pw.Paragraph(text: pConstraints.trim().isEmpty ? pText.proBriefNoConstraints : pConstraints),
        pw.Header(level: 1, text: pText.proBriefMeasures),
        ...roomSheetGeometry(pText, pRoom),
        if (vFixtures.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.proBriefContents),
          pw.Paragraph(
            text: [
              for (final vEntry in vFixtures.entries)
                '${vEntry.value} × ${fixtureLabel(pText, vEntry.key)}',
            ].join(', '),
          ),
        ],
        if (vPhotos.isNotEmpty) ...[
          pw.Header(level: 1, text: pText.proBriefPhotos),
          pw.Wrap(spacing: 8, runSpacing: 8, children: vPhotos),
        ],
        pw.Paragraph(text: pText.proBriefFooter),
      ],
    ),
  );

  return vDocument.save();
}
