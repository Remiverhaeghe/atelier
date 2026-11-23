import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../l10n/gen/app_localizations.dart';
import '../logic/climate_history.dart';
import '../logic/indoor_climate.dart';
import '../logic/units.dart';
import 'climate_history_view.dart' show climateDayText;

/// Partie « humidité » de la fiche de la pièce : courbe des derniers jours suivis, puis la
/// comparaison avant et après travaux. Rien quand la pièce n'a pas de suivi.
List<pw.Widget> climateSheetSection(AppLocalizations pText, ClimateLog pLog) {
  final vDays = recentClimateDays(pLog.days, sheetClimateDays);
  if (vDays.isEmpty) {
    return const [];
  }
  final vComparison = compareClimate(pLog);
  String vPeriod(ClimatePeriod pPeriod) => pText.climatePeriodSummary(
    formatDecimal(pPeriod.humidity.roundToDouble()),
    formatDecimal((pPeriod.tempC * 10).roundToDouble() / 10),
    pPeriod.dampDays,
    pPeriod.days,
  );
  final vWorks = pLog.worksOn;

  final rSection = <pw.Widget>[
    pw.Header(level: 1, text: pText.roomSheetClimate(sheetClimateDays)),
    pw.Paragraph(
      text: pText.climateHistoryDays(
        vDays.length,
        climateDayText(vDays.first.day),
        climateDayText(vDays.last.day),
      ),
    ),
    pw.SizedBox(
      width: sheetClimateWidth,
      height: sheetClimateWidth / 3,
      child: _curve(vDays, vWorks),
    ),
    pw.SizedBox(height: 6),
    pw.Paragraph(text: pText.climateHistoryHelp),
    if (vWorks != null) pw.Paragraph(text: pText.climateWorksOn(climateDayText(vWorks))),
    if (vComparison != null) ...[
      pw.Paragraph(text: pText.climateBefore(vPeriod(vComparison.before))),
      pw.Paragraph(text: pText.climateAfter(vPeriod(vComparison.after))),
      pw.Paragraph(
        text: switch (climateTrend(vComparison)) {
          ClimateTrend.drier => pText.climateDrier(
            formatDecimal(
              (vComparison.before.humidity - vComparison.after.humidity).roundToDouble(),
            ),
          ),
          ClimateTrend.damper => pText.climateDamper(
            formatDecimal(
              (vComparison.after.humidity - vComparison.before.humidity).roundToDouble(),
            ),
          ),
          ClimateTrend.same => pText.climateSame(formatDecimal(climateTrendPoints)),
        },
      ),
    ],
  ];

  return rSection;
}

/// Largeur de la courbe d'humidité sur la fiche, en points.
const sheetClimateWidth = 480.0;

/// Humidité moyenne par jour de 20 à 100 %, bande de la zone saine, trait des 70 % et jour des
/// travaux en tirets. Le PDF compte les y depuis le bas de la page.
pw.Widget _curve(List<ClimateDay> pDays, DateTime? pWorks) => pw.CustomPaint(
  size: const PdfPoint(sheetClimateWidth, sheetClimateWidth / 3),
  painter: (pCanvas, pSize) {
    const vLow = 20.0;
    const vHigh = 100.0;
    final vFirst = pDays.first.day;
    final vSpan = pDays.last.day.difference(vFirst).inDays;
    double vX(DateTime pDay) =>
        vSpan == 0 ? pSize.x / 2 : pDay.difference(vFirst).inDays / vSpan * pSize.x;
    double vY(double pHumidity) => (pHumidity.clamp(vLow, vHigh) - vLow) / (vHigh - vLow) * pSize.y;

    pCanvas
      ..setFillColor(PdfColors.green50)
      ..drawRect(
        0,
        vY(comfortHumidityLow),
        pSize.x,
        vY(comfortHumidityHigh) - vY(comfortHumidityLow),
      )
      ..fillPath()
      ..setStrokeColor(PdfColors.grey500)
      ..setLineWidth(0.5)
      ..moveTo(0, vY(dampHumidity))
      ..lineTo(pSize.x, vY(dampHumidity))
      ..strokePath();

    pCanvas
      ..setStrokeColor(PdfColors.blueGrey800)
      ..setLineWidth(1.2);
    for (final (vIndex, vDay) in pDays.indexed) {
      if (vIndex == 0) {
        pCanvas.moveTo(vX(vDay.day), vY(vDay.humidity));
      } else {
        pCanvas.lineTo(vX(vDay.day), vY(vDay.humidity));
      }
    }
    pCanvas.strokePath();

    if (pWorks != null) {
      final vWorksDay = DateTime(pWorks.year, pWorks.month, pWorks.day);
      if (!vWorksDay.isBefore(vFirst) && !vWorksDay.isAfter(pDays.last.day)) {
        pCanvas
          ..setStrokeColor(PdfColors.orange700)
          ..setLineWidth(1.5)
          ..setLineDashPattern([3, 3])
          ..moveTo(vX(vWorksDay), 0)
          ..lineTo(vX(vWorksDay), pSize.y)
          ..strokePath()
          ..setLineDashPattern();
      }
    }
  },
);
