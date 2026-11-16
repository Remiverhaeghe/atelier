import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/outdoor_weather.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String outdoorJobLabel(AppLocalizations pText, OutdoorJob pJob) => switch (pJob) {
  OutdoorJob.facadePaint => pText.outdoorFacade,
  OutdoorJob.render => pText.outdoorRender,
  OutdoorJob.concrete => pText.outdoorConcrete,
  OutdoorJob.woodStain => pText.outdoorStain,
  OutdoorJob.roofing => pText.outdoorRoofing,
};

String weatherIssueLabel(AppLocalizations pText, WeatherIssue pIssue) => switch (pIssue) {
  WeatherIssue.cold => pText.weatherCold,
  WeatherIssue.hot => pText.weatherHot,
  WeatherIssue.rain => pText.weatherRain,
  WeatherIssue.rainAfter => pText.weatherRainAfter,
  WeatherIssue.frostAfter => pText.weatherFrostAfter,
  WeatherIssue.wind => pText.weatherWind,
};

int? _parseSigned(String pText) => parseSignedDecimal(pText)?.round();

/// Prévisions des jours qui viennent, recopiées à la main, et les jours bons pour un travail.
class OutdoorWeatherCalculator extends StatefulWidget {
  const OutdoorWeatherCalculator({super.key});

  @override
  State<OutdoorWeatherCalculator> createState() => _OutdoorWeatherCalculatorState();
}

class _OutdoorWeatherCalculatorState extends State<OutdoorWeatherCalculator> {
  OutdoorJob _job = OutdoorJob.facadePaint;
  final _days = <DayForecast>[
    for (var vIndex = 0; vIndex < 5; vIndex++) (minC: 8, maxC: 18, rain: false, windKmh: 15),
  ];

  void _set(int pIndex, {int? pMin, int? pMax, bool? pRain, int? pWind}) => setState(() {
    final vDay = _days[pIndex];
    _days[pIndex] = (
      minC: pMin ?? vDay.minC,
      maxC: pMax ?? vDay.maxC,
      rain: pRain ?? vDay.rain,
      windKmh: pWind ?? vDay.windKmh,
    );
  });

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vGood = goodDays(_job, _days);

    return Scaffold(
      appBar: AppBar(title: Text(vText.outdoorTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          DropdownButtonFormField<OutdoorJob>(
            initialValue: _job,
            decoration: InputDecoration(labelText: vText.outdoorJob),
            items: [
              for (final vJob in OutdoorJob.values)
                DropdownMenuItem(value: vJob, child: Text(outdoorJobLabel(vText, vJob))),
            ],
            onChanged: (pJob) => setState(() => _job = pJob!),
          ),
          const SizedBox(height: 12),
          BigFigure(
            vGood.isEmpty
                ? vText.outdoorNone
                : vText.outdoorGood(vGood.map((pIndex) => '${pIndex + 1}').join(', ')),
          ),
          for (var vIndex = 0; vIndex < _days.length; vIndex++)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vText.outdoorDay(vIndex + 1),
                            style: vTheme.textTheme.titleMedium,
                          ),
                        ),
                        Text(vText.weatherRainLabel),
                        Switch(
                          value: _days[vIndex].rain,
                          onChanged: (pRain) => _set(vIndex, pRain: pRain),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: NumberField<int>(
                            key: ValueKey('min-$vIndex'),
                            label: vText.weatherMin,
                            initial: '${_days[vIndex].minC}',
                            parse: _parseSigned,
                            onValue: (pValue) => _set(vIndex, pMin: pValue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NumberField<int>(
                            key: ValueKey('max-$vIndex'),
                            label: vText.weatherMax,
                            initial: '${_days[vIndex].maxC}',
                            parse: _parseSigned,
                            onValue: (pValue) => _set(vIndex, pMax: pValue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: NumberField<int>(
                            key: ValueKey('wind-$vIndex'),
                            label: vText.weatherWindLabel,
                            initial: '${_days[vIndex].windKmh}',
                            parse: parseWhole,
                            onValue: (pValue) => _set(vIndex, pWind: pValue),
                          ),
                        ),
                      ],
                    ),
                    if (weatherIssues(_job, _days, vIndex) case final vIssues
                        when vIssues.isNotEmpty)
                      Text(
                        vIssues.map((pIssue) => weatherIssueLabel(vText, pIssue)).join(', '),
                        style: TextStyle(color: vTheme.colorScheme.error),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          IconLine(Icons.info_outline, vText.outdoorHint),
        ],
      ),
    );
  }
}
