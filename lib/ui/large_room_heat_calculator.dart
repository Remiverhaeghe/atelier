import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/heating.dart';
import '../logic/large_room_heating.dart';
import '../logic/units.dart';
import 'heating_screen.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Chauffer un grand volume : puissance, air chaud sous le plafond, brasseurs, poêle.
class LargeRoomHeatCalculator extends StatefulWidget {
  const LargeRoomHeatCalculator({super.key});

  @override
  State<LargeRoomHeatCalculator> createState() => _LargeRoomHeatCalculatorState();
}

class _LargeRoomHeatCalculatorState extends State<LargeRoomHeatCalculator> {
  var _lengthMm = 8000;
  var _widthMm = 6000;
  var _heightMm = 5000;
  var _level = InsulationLevel.good;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vHeat = heatLargeRoom(
      pLengthMm: _lengthMm,
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pLevel: _level,
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.largeHeatTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.heatTotal, style: vTheme.textTheme.titleMedium),
                  BigFigure('${vHeat.watts} W'),
                  if (vHeat.stratificationWatts > 0)
                    IconLine(
                      Icons.arrow_upward,
                      vText.largeHeatStratification(vHeat.stratificationWatts),
                    ),
                  if (vHeat.radiators.isNotEmpty)
                    IconLine(
                      Icons.local_fire_department_outlined,
                      vText.heatRadiators(vHeat.radiators.length, vHeat.radiators.first),
                    ),
                  IconLine(Icons.fireplace_outlined, vText.largeHeatStove(vHeat.stoveKw)),
                  if (vHeat.fans > 0)
                    IconLine(
                      Icons.wind_power_outlined,
                      vText.largeHeatFans(vHeat.fans, formatCentimetres(vHeat.fanDiameterMm)),
                    ),
                  IconLine(
                    Icons.lightbulb_outline,
                    vHeat.preferRadiant ? vText.largeHeatRadiant : vText.largeHeatConvection,
                  ),
                  Text(vText.heatHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InsulationLevel>(
            initialValue: _level,
            decoration: InputDecoration(labelText: vText.heatLevel),
            items: [
              for (final vLevel in InsulationLevel.values)
                DropdownMenuItem(value: vLevel, child: Text(insulationLevelLabel(vText, vLevel))),
            ],
            onChanged: (pLevel) => setState(() => _level = pLevel!),
          ),
          NumberField(
            label: vText.largeRoomLength,
            initial: formatCentimetres(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          NumberField(
            label: vText.largeRoomWidth,
            initial: formatCentimetres(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.largeRoomHeight,
            initial: formatCentimetres(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
        ],
      ),
    );
  }
}
