import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

pw.ThemeData? _aTheme;

/// Thème des PDF avec la police Barlow de l'appli : l'Helvetica par défaut du PDF n'a ni « € »
/// ni certains accents, qui disparaissaient de la fiche imprimée.
Future<pw.ThemeData> pdfTheme() async {
  final vCached = _aTheme;
  if (vCached != null) {
    return vCached;
  }
  try {
    final vRegular = await rootBundle.load('assets/fonts/Barlow-Regular.ttf');
    final vBold = await rootBundle.load('assets/fonts/Barlow-SemiBold.ttf');
    final vItalic = await rootBundle.load('assets/fonts/Barlow-Italic.ttf');
    final rTheme = pw.ThemeData.withFont(
      base: pw.Font.ttf(vRegular),
      bold: pw.Font.ttf(vBold),
      italic: pw.Font.ttf(vItalic),
    );
    _aTheme = rTheme;

    return rTheme;
  } on FlutterError {
    // Police introuvable (tests sans assets) : le PDF reste lisible avec la police par défaut
    return pw.ThemeData.base();
  }
}
