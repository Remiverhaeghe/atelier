import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/indoor_climate.dart';
import '../logic/touch_up.dart';
import '../logic/units.dart';
import 'theme.dart';

/// Lit le texte d'un fichier choisi par l'utilisateur ; null s'il renonce.
typedef TextFilePicker = Future<String?> Function();

Future<String?> pickTextFile() async {
  final vFile = await FilePicker.pickFile();
  final rText = vFile == null ? null : utf8.decode(await vFile.readAsBytes(), allowMalformed: true);

  return rText;
}

/// Relevés de température et d'humidité d'une pièce : fichier exporté par le
/// thermo-hygromètre, analyse, et constats à garder comme reprises.
///
/// Ouvert depuis les reprises d'une pièce, l'écran renvoie les reprises cochées ;
/// ouvert depuis les calculs, il ne fait que l'analyse.
class ClimateScreen extends StatefulWidget {
  const ClimateScreen({super.key, this.canAddTouchUps = false, this.pickFile});

  final bool canAddTouchUps;
  final TextFilePicker? pickFile;

  @override
  State<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends State<ClimateScreen> {
  ClimateImport? _import;
  bool _unreadable = false;
  ClimateRoom _room = ClimateRoom.living;
  final _chosen = <ClimateFinding>{};

  Future<void> _load() async {
    final vText = await (widget.pickFile ?? pickTextFile)();
    if (vText == null || !mounted) {
      return;
    }
    final vImport = parseClimateCsv(vText);
    setState(() {
      _unreadable = vImport == null || vImport.readings.isEmpty;
      _import = _unreadable ? null : vImport;
      _chosen.clear();
    });
  }

  String _percent(double pShare) => formatDecimal((pShare * 100).roundToDouble());

  String _day(DateTime pDay) =>
      '${pDay.day.toString().padLeft(2, '0')}/${pDay.month.toString().padLeft(2, '0')}/${pDay.year}';

  /// Constat et conseil de chaque situation.
  (String, String) _texts(AppLocalizations pText, ClimateFinding pFinding, ClimateReport pReport) {
    final vReference = formatDecimal(referenceTempC(_room));
    final rTexts = switch (pFinding) {
      ClimateFinding.damp => (pText.climateDamp(_percent(pReport.dampShare)), pText.climateDampFix),
      ClimateFinding.slowDrying => (
        pText.climateSlowDrying(formatDecimal(pReport.dryingHours ?? 0)),
        pText.climateSlowDryingFix,
      ),
      ClimateFinding.nightDrop => (
        pText.climateNightDrop(formatDecimal(pReport.nightDropC ?? 0)),
        pText.climateNightDropFix,
      ),
      ClimateFinding.cold => (
        pText.climateCold(formatDecimal(pReport.meanTempC), vReference),
        pText.climateColdFix,
      ),
      ClimateFinding.warm => (
        pText.climateWarm(formatDecimal(pReport.meanTempC), vReference),
        pText.climateWarmFix,
      ),
      ClimateFinding.dry => (pText.climateDry(_percent(pReport.dryShare)), pText.climateDryFix),
      ClimateFinding.healthy => (pText.climateHealthy, ''),
    };

    return rTexts;
  }

  String _title(AppLocalizations pText, ClimateFinding pFinding) => switch (pFinding) {
    ClimateFinding.damp => pText.climateDampTitle,
    ClimateFinding.slowDrying => pText.climateSlowDryingTitle,
    ClimateFinding.nightDrop => pText.climateNightDropTitle,
    ClimateFinding.cold => pText.climateColdTitle,
    ClimateFinding.warm => pText.climateWarmTitle,
    ClimateFinding.dry => pText.climateDryTitle,
    ClimateFinding.healthy => pText.climateHealthyTitle,
  };

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vImport = _import;
    final vReport = vImport == null ? null : analyseClimate(vImport.readings, _room);

    return Scaffold(
      appBar: AppBar(title: Text(vText.climateTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.climateIntro, style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(vImport == null ? vText.climatePick : vText.climatePickOther),
          ),
          if (_unreadable)
            IconLine(Icons.error_outline, vText.climateUnreadable, color: vTheme.colorScheme.error),
          const SizedBox(height: 12),
          Text(vText.climateRoomKind, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 6,
            children: [
              for (final vKind in ClimateRoom.values)
                ChoiceChip(
                  label: Text(switch (vKind) {
                    ClimateRoom.living => vText.climateRoomLiving,
                    ClimateRoom.bedroom => vText.climateRoomBedroom,
                    ClimateRoom.bathroom => vText.climateRoomBathroom,
                    ClimateRoom.kitchen => vText.climateRoomKitchen,
                  }),
                  selected: _room == vKind,
                  onSelected: (_) => setState(() {
                    _room = vKind;
                    _chosen.clear();
                  }),
                ),
            ],
          ),
          if (vImport != null && vReport != null) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vText.climatePeriod(_day(vReport.from), _day(vReport.to), vReport.count),
                      style: vTheme.textTheme.titleMedium,
                    ),
                    if (vImport.skipped > 0)
                      Text(
                        vText.climateSkipped(vImport.skipped),
                        style: vTheme.textTheme.bodySmall,
                      ),
                    IconLine(
                      Icons.thermostat_outlined,
                      vText.climateTemp(
                        formatDecimal(vReport.meanTempC),
                        formatDecimal(vReport.minTempC),
                        formatDecimal(vReport.maxTempC),
                      ),
                    ),
                    IconLine(
                      Icons.water_drop_outlined,
                      vText.climateHumidity(
                        formatDecimal(vReport.meanHumidity.roundToDouble()),
                        _percent(vReport.comfortShare),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: vReport.comfortShare),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, pValue, _) =>
                            LinearProgressIndicator(value: pValue, minHeight: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (final vFinding in vReport.findings)
              Card(
                margin: const EdgeInsets.only(top: 10),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_title(vText, vFinding), style: vTheme.textTheme.titleSmall),
                            Text(_texts(vText, vFinding, vReport).$1),
                            if (_texts(vText, vFinding, vReport).$2.isNotEmpty)
                              IconLine(Icons.build_outlined, _texts(vText, vFinding, vReport).$2),
                          ],
                        ),
                      ),
                      if (widget.canAddTouchUps && vFinding != ClimateFinding.healthy)
                        Checkbox(
                          value: _chosen.contains(vFinding),
                          onChanged: (pValue) => setState(
                            () => pValue == true ? _chosen.add(vFinding) : _chosen.remove(vFinding),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.canAddTouchUps && _chosen.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () {
                    final vId = DateTime.now().microsecondsSinceEpoch;
                    Navigator.pop(context, [
                      for (final (vIndex, vFinding) in _chosen.indexed)
                        TouchUp(
                          id: '$vId-$vIndex',
                          label: _title(vText, vFinding),
                          note:
                              '${_texts(vText, vFinding, vReport).$1}\n${_texts(vText, vFinding, vReport).$2}',
                        ),
                    ]);
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: Text(vText.climateAdd(_chosen.length)),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(vText.climateHowTo, style: vTheme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(vText.climateBasis, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
