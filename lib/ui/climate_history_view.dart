import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/climate_history.dart';
import '../logic/indoor_climate.dart';
import '../logic/units.dart';
import 'theme.dart';

String climateDayText(DateTime pDay) =>
    '${pDay.day.toString().padLeft(2, '0')}/${pDay.month.toString().padLeft(2, '0')}/${pDay.year}';

/// Suivi de la pièce : courbe de l'humidité par jour, date des travaux et comparaison
/// avant / après.
class ClimateHistoryCard extends StatelessWidget {
  const ClimateHistoryCard({super.key, required this.log, required this.onChanged});

  final ClimateLog log;
  final ValueChanged<ClimateLog> onChanged;

  Future<void> _pickWorks(BuildContext pContext) async {
    final vDays = log.days;
    final vPicked = await showDatePicker(
      context: pContext,
      initialDate: log.worksOn ?? vDays[vDays.length ~/ 2].day,
      firstDate: vDays.first.day.subtract(const Duration(days: 365)),
      lastDate: vDays.last.day.add(const Duration(days: 365)),
    );
    if (vPicked != null) {
      onChanged(log.copyWith(worksOn: vPicked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vWorks = log.worksOn;
    final vComparison = compareClimate(log);
    String vPeriod(ClimatePeriod pPeriod) => vText.climatePeriodSummary(
      formatDecimal(pPeriod.humidity.roundToDouble()),
      formatDecimal((pPeriod.tempC * 10).roundToDouble() / 10),
      pPeriod.dampDays,
      pPeriod.days,
    );

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.climateHistoryTitle, style: vTheme.textTheme.titleMedium),
            Text(
              vText.climateHistoryDays(
                log.days.length,
                climateDayText(log.days.first.day),
                climateDayText(log.days.last.day),
              ),
              style: vTheme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Semantics(
              label: vText.climateHistoryChart,
              child: AspectRatio(
                aspectRatio: 2,
                child: CustomPaint(
                  painter: _HumidityPainter(
                    days: log.days,
                    worksOn: vWorks,
                    line: vTheme.colorScheme.primary,
                    band: vTheme.colorScheme.primaryContainer,
                    ink: AtelierColors.of(context).ink,
                    works: AtelierColors.of(context).tape,
                  ),
                ),
              ),
            ),
            Text(vText.climateHistoryHelp, style: vTheme.textTheme.bodySmall),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickWorks(context),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    vWorks == null ? vText.climateWorksPick : vText.climateWorksOn(climateDayText(vWorks)),
                  ),
                ),
                if (vWorks != null)
                  TextButton(
                    onPressed: () => onChanged(log.copyWith(clearWorks: true)),
                    child: Text(vText.climateWorksClear),
                  ),
              ],
            ),
            if (vWorks != null && vComparison == null)
              IconLine(Icons.info_outline, vText.climateNeedBoth),
            if (vComparison != null) ...[
              IconLine(Icons.history, vText.climateBefore(vPeriod(vComparison.before))),
              IconLine(Icons.update, vText.climateAfter(vPeriod(vComparison.after))),
              IconLine(
                switch (climateTrend(vComparison)) {
                  ClimateTrend.drier => Icons.check_circle_outline,
                  ClimateTrend.damper => Icons.warning_amber_outlined,
                  ClimateTrend.same => Icons.drag_handle,
                },
                switch (climateTrend(vComparison)) {
                  ClimateTrend.drier => vText.climateDrier(
                    formatDecimal(
                      (vComparison.before.humidity - vComparison.after.humidity).roundToDouble(),
                    ),
                  ),
                  ClimateTrend.damper => vText.climateDamper(
                    formatDecimal(
                      (vComparison.after.humidity - vComparison.before.humidity).roundToDouble(),
                    ),
                  ),
                  ClimateTrend.same => vText.climateSame(formatDecimal(climateTrendPoints)),
                },
                color: climateTrend(vComparison) == ClimateTrend.damper
                    ? vTheme.colorScheme.error
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Humidité moyenne par jour, sur une échelle de 20 à 100 % ; bande de la zone saine et trait
/// vertical le jour des travaux.
class _HumidityPainter extends CustomPainter {
  _HumidityPainter({
    required this.days,
    required this.worksOn,
    required this.line,
    required this.band,
    required this.ink,
    required this.works,
  });

  final List<ClimateDay> days;
  final DateTime? worksOn;
  final Color line;
  final Color band;
  final Color ink;
  final Color works;

  static const _low = 20.0;
  static const _high = 100.0;

  @override
  void paint(Canvas pCanvas, Size pSize) {
    final vFirst = days.first.day;
    final vSpan = math.max(days.last.day.difference(vFirst).inDays, 1);
    double vX(DateTime pDay) => pDay.difference(vFirst).inDays / vSpan * pSize.width;
    double vY(double pHumidity) =>
        pSize.height * (1 - ((pHumidity.clamp(_low, _high) - _low) / (_high - _low)));

    pCanvas.drawRect(
      Rect.fromLTRB(0, vY(comfortHumidityHigh), pSize.width, vY(comfortHumidityLow)),
      Paint()..color = band.withValues(alpha: 0.5),
    );
    final vGrid = Paint()
      ..color = ink.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    pCanvas.drawLine(Offset(0, vY(dampHumidity)), Offset(pSize.width, vY(dampHumidity)), vGrid);

    final vPath = Path();
    for (final (vIndex, vDay) in days.indexed) {
      final vPoint = Offset(vX(vDay.day), vY(vDay.humidity));
      if (vIndex == 0) {
        vPath.moveTo(vPoint.dx, vPoint.dy);
      } else {
        vPath.lineTo(vPoint.dx, vPoint.dy);
      }
      pCanvas.drawCircle(vPoint, 2.5, Paint()..color = line);
    }
    pCanvas.drawPath(
      vPath,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final vWorks = worksOn;
    if (vWorks != null) {
      final vAt = vX(DateTime(vWorks.year, vWorks.month, vWorks.day)).clamp(0.0, pSize.width).toDouble();
      final vPaint = Paint()
        ..color = works
        ..strokeWidth = 3;
      for (var vDone = 0.0; vDone < pSize.height; vDone += 10) {
        pCanvas.drawLine(
          Offset(vAt, vDone),
          Offset(vAt, math.min(vDone + 5, pSize.height)),
          vPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HumidityPainter pOld) => pOld.days != days || pOld.worksOn != worksOn;
}
