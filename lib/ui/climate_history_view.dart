import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/climate_history.dart';
import '../logic/indoor_climate.dart';
import '../logic/units.dart';
import 'share_file.dart';
import 'theme.dart';

String climateDayText(DateTime pDay) =>
    '${pDay.day.toString().padLeft(2, '0')}/${pDay.month.toString().padLeft(2, '0')}/${pDay.year}';

/// Suivi de la pièce : courbe de l'humidité par jour, date des travaux et comparaison
/// avant / après.
class ClimateHistoryCard extends StatefulWidget {
  const ClimateHistoryCard({
    super.key,
    required this.log,
    required this.onChanged,
    this.others = const [],
  });

  final ClimateLog log;
  final ValueChanged<ClimateLog> onChanged;

  /// Autres pièces du chantier qui ont un suivi, à comparer à celle-ci.
  final List<NamedClimate> others;

  @override
  State<ClimateHistoryCard> createState() => _ClimateHistoryCardState();
}

class _ClimateHistoryCardState extends State<ClimateHistoryCard> {
  NamedClimate? _other;

  ClimateLog get log => widget.log;
  ValueChanged<ClimateLog> get onChanged => widget.onChanged;

  Future<void> _pickOther(BuildContext pContext) async {
    // Une seule autre pièce : pas de choix à faire, un geste suffit.
    if (widget.others.length == 1) {
      setState(() => _other = widget.others.single);

      return;
    }
    final vText = AppLocalizations.of(pContext);
    final vPicked = await showDialog<NamedClimate>(
      context: pContext,
      builder: (pDialog) => SimpleDialog(
        title: Text(vText.climateCompareTitle),
        children: [
          for (final vOther in widget.others)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(pDialog, vOther),
              child: Text(vOther.name),
            ),
        ],
      ),
    );
    if (vPicked != null) {
      setState(() => _other = vPicked);
    }
  }

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
                    other: _other?.log.days,
                    otherLine: vTheme.colorScheme.tertiary,
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
                    vWorks == null
                        ? vText.climateWorksPick
                        : vText.climateWorksOn(climateDayText(vWorks)),
                  ),
                ),
                if (vWorks != null)
                  TextButton(
                    onPressed: () => onChanged(log.copyWith(clearWorks: true)),
                    child: Text(vText.climateWorksClear),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      shareTextFile('suivi-humidite.csv', climateCsv(log), pMime: 'text/csv'),
                  icon: const Icon(Icons.ios_share),
                  label: Text(vText.climateExportCsv),
                ),
                if (widget.others.isNotEmpty)
                  _other == null
                      ? OutlinedButton.icon(
                          onPressed: () => _pickOther(context),
                          icon: const Icon(Icons.compare_arrows),
                          label: Text(vText.climateCompareButton),
                        )
                      : TextButton(
                          onPressed: () => setState(() => _other = null),
                          child: Text(vText.climateCompareClear),
                        ),
              ],
            ),
            if (_other case final vOther?) ..._roomLines(vText, vTheme, vOther),
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

extension on _ClimateHistoryCardState {
  /// Légende des deux courbes, puis ce que la comparaison des jours communs en dit.
  List<Widget> _roomLines(AppLocalizations pText, ThemeData pTheme, NamedClimate pOther) {
    final vComparison = compareRoomsClimate(log, pOther.log);
    String vPeriod(ClimatePeriod pPeriod) => pText.climatePeriodSummary(
      formatDecimal(pPeriod.humidity.roundToDouble()),
      formatDecimal((pPeriod.tempC * 10).roundToDouble() / 10),
      pPeriod.dampDays,
      pPeriod.days,
    );
    final rLines = <Widget>[
      IconLine(Icons.show_chart, pText.climateCompareLegend(pText.climateCompareThis, pOther.name)),
    ];
    if (vComparison == null) {
      rLines.add(IconLine(Icons.info_outline, pText.climateCompareNoCommon));

      return rLines;
    }
    final vPoints = formatDecimal(
      (vComparison.first.humidity - vComparison.second.humidity).abs().roundToDouble(),
    );
    rLines
      ..add(
        IconLine(
          Icons.home_outlined,
          '${pText.climateCompareThis} : ${vPeriod(vComparison.first)}',
        ),
      )
      ..add(IconLine(Icons.home_work_outlined, '${pOther.name} : ${vPeriod(vComparison.second)}'))
      ..add(
        IconLine(Icons.compare_arrows, switch (roomGap(vComparison)) {
          RoomGap.firstDrier => pText.climateCompareDrier(
            pText.climateCompareThis,
            vPoints,
            vComparison.first.days,
          ),
          RoomGap.secondDrier => pText.climateCompareDrier(
            pOther.name,
            vPoints,
            vComparison.first.days,
          ),
          RoomGap.same => pText.climateCompareSame(
            formatDecimal(climateTrendPoints),
            vComparison.first.days,
          ),
        }),
      );

    return rLines;
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
    this.other,
    this.otherLine = Colors.teal,
  });

  /// Jours d'une autre pièce, tracés sur la même échelle de dates.
  final List<ClimateDay>? other;
  final Color otherLine;

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
    final vOther = other ?? const <ClimateDay>[];
    final vFirst = vOther.isEmpty || days.first.day.isBefore(vOther.first.day)
        ? days.first.day
        : vOther.first.day;
    final vLast = vOther.isEmpty || days.last.day.isAfter(vOther.last.day)
        ? days.last.day
        : vOther.last.day;
    final vSpan = math.max(vLast.difference(vFirst).inDays, 1);
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

    void curve(List<ClimateDay> pDays, Color pColor, {bool pSquare = false}) {
      final vPath = Path();
      for (final (vIndex, vDay) in pDays.indexed) {
        final vPoint = Offset(vX(vDay.day), vY(vDay.humidity));
        if (vIndex == 0) {
          vPath.moveTo(vPoint.dx, vPoint.dy);
        } else {
          vPath.lineTo(vPoint.dx, vPoint.dy);
        }
        if (pSquare) {
          pCanvas.drawRect(
            Rect.fromCenter(center: vPoint, width: 5, height: 5),
            Paint()..color = pColor,
          );
        } else {
          pCanvas.drawCircle(vPoint, 2.5, Paint()..color = pColor);
        }
      }
      pCanvas.drawPath(
        vPath,
        Paint()
          ..color = pColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    curve(days, line);
    if (vOther.isNotEmpty) {
      curve(vOther, otherLine, pSquare: true);
    }

    final vWorks = worksOn;
    if (vWorks != null) {
      final vAt = vX(
        DateTime(vWorks.year, vWorks.month, vWorks.day),
      ).clamp(0.0, pSize.width).toDouble();
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
  bool shouldRepaint(_HumidityPainter pOld) =>
      pOld.days != days || pOld.worksOn != worksOn || pOld.other != other;
}
