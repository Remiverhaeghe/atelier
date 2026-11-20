import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/thermal.dart';
import '../logic/units.dart';
import 'parquet_view.dart' show NumberField;
import 'theme.dart';

/// Températures relevées sur l'image thermique, et ce qu'elles disent de la zone froide.
///
/// [onNote] reçoit la ligne à garder dans la reprise, ou null tant que le relevé est incomplet.
class ThermalReadingCard extends StatefulWidget {
  const ThermalReadingCard({super.key, required this.onNote});

  final ValueChanged<String?> onNote;

  @override
  State<ThermalReadingCard> createState() => _ThermalReadingCardState();
}

class _ThermalReadingCardState extends State<ThermalReadingCard> {
  double? _spot;
  double? _wall;
  double _inside = 19;
  double _outside = 5;
  double? _humidity;

  ThermalReading? _reading() {
    final vSpot = _spot;
    final vWall = _wall;
    final rReading = vSpot == null || vWall == null
        ? null
        : readThermal(
            spotC: vSpot,
            wallC: vWall,
            insideC: _inside,
            outsideC: _outside,
            humidityPercent: _humidity,
          );

    return rReading;
  }

  void _changed(VoidCallback pChange) {
    setState(pChange);
    final vReading = _reading();
    widget.onNote(
      vReading == null
          ? null
          : AppLocalizations.of(context).thermalReadNote(
              formatDecimal(_spot!),
              formatDecimal(_wall!),
              formatDecimal(_inside),
              formatDecimal(_outside),
              formatDecimal(vReading.factor),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vReading = _reading();
    final vTooFlat = _spot != null && _wall != null && vReading == null;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.thermostat_outlined),
      title: Text(vText.thermalReadTitle),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vText.thermalReadHelp, style: vTheme.textTheme.bodySmall),
        NumberField<double>(
          label: vText.thermalSpot,
          initial: '',
          parse: parseSignedDecimal,
          onValue: (pValue) => _changed(() => _spot = pValue),
        ),
        NumberField<double>(
          label: vText.thermalWallTemp,
          initial: '',
          parse: parseSignedDecimal,
          onValue: (pValue) => _changed(() => _wall = pValue),
        ),
        NumberField<double>(
          label: vText.thermalInside,
          initial: formatDecimal(_inside),
          parse: parseSignedDecimal,
          onValue: (pValue) => _changed(() => _inside = pValue),
        ),
        NumberField<double>(
          label: vText.thermalOutside,
          initial: formatDecimal(_outside),
          parse: parseSignedDecimal,
          onValue: (pValue) => _changed(() => _outside = pValue),
        ),
        NumberField<double>(
          label: vText.thermalHumidity,
          initial: '',
          parse: (pText) => switch (parseDecimal(pText)) {
            final double vValue when vValue <= 100 => vValue,
            _ => null,
          },
          onValue: (pValue) => _changed(() => _humidity = pValue),
        ),
        const SizedBox(height: 8),
        if (vTooFlat)
          IconLine(
            Icons.info_outline,
            vText.thermalGapTooSmall(formatDecimal(minThermalGapCelsius)),
          ),
        if (vReading != null) ...[
          IconLine(Icons.straighten, vText.thermalFactor(formatDecimal(vReading.factor))),
          IconLine(
            switch (vReading.severity) {
              ThermalSeverity.none || ThermalSeverity.mild => Icons.check_circle_outline,
              _ => Icons.warning_amber_outlined,
            },
            switch (vReading.severity) {
              ThermalSeverity.none => vText.thermalNone,
              ThermalSeverity.mild => vText.thermalMild,
              ThermalSeverity.mouldRisk => vText.thermalMould(formatDecimal(mouldFactor)),
              ThermalSeverity.condensation => vText.thermalCondensation,
            },
            color: switch (vReading.severity) {
              ThermalSeverity.mouldRisk || ThermalSeverity.condensation => vTheme.colorScheme.error,
              _ => null,
            },
          ),
        ],
        Text(vText.thermalReadHint, style: vTheme.textTheme.bodySmall),
        const SizedBox(height: 8),
      ],
    );
  }
}
