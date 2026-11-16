import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/heating.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'parquet_view.dart';
import 'theme.dart';

String insulationLevelLabel(AppLocalizations pText, InsulationLevel pLevel) => switch (pLevel) {
  InsulationLevel.recent => pText.heatRecent,
  InsulationLevel.good => pText.heatGood,
  InsulationLevel.average => pText.heatAverage,
  InsulationLevel.poor => pText.heatPoor,
};

/// Chauffage : puissance par pièce et radiateurs courants, plexis et grande hauteur signalés.
class HeatingScreen extends StatefulWidget {
  const HeatingScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  State<HeatingScreen> createState() => _HeatingScreenState();
}

class _HeatingScreenState extends State<HeatingScreen> {
  InsulationLevel _level = InsulationLevel.average;
  double _outdoor = -7;
  double _indoor = 19;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRooms = [
      for (final vRoom in widget.controller.worksite(widget.worksiteId)?.rooms ?? const <Room>[])
        if (vRoom.walls.length >= 3 && vRoom.usage == RoomUsage.habitable) vRoom,
    ];
    final vNeeds = [
      for (final vRoom in vRooms)
        (room: vRoom, need: heatNeed(vRoom, _level, pIndoorC: _indoor, pOutdoorC: _outdoor)),
    ];
    final vTotal = vNeeds.fold(0, (pSum, pEntry) => pSum + pEntry.need.watts);

    return Scaffold(
      appBar: AppBar(title: Text(vText.heatTitle)),
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
                  BigFigure('$vTotal W'),
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
          NumberField<double>(
            label: vText.heatOutdoor,
            initial: formatDecimal(_outdoor),
            parse: parseSignedDecimal,
            onValue: (pValue) => setState(() => _outdoor = pValue),
          ),
          NumberField<double>(
            label: vText.heatIndoor,
            initial: formatDecimal(_indoor),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _indoor = pValue),
          ),
          const SizedBox(height: 12),
          if (vNeeds.isEmpty) Text(vText.heatEmpty),
          for (final vEntry in vNeeds)
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_fire_department_outlined),
                title: Text('${vEntry.room.name} : ${vEntry.need.watts} W'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vEntry.need.radiators.isNotEmpty)
                      Text(
                        vText.heatRadiators(
                          vEntry.need.radiators.length,
                          vEntry.need.radiators.first,
                        ),
                      ),
                    if (vEntry.need.plexiWatts > 0)
                      IconLine(Icons.roofing_outlined, vText.heatPlexi(vEntry.need.plexiWatts)),
                    if (vEntry.need.destratify)
                      IconLine(Icons.wind_power_outlined, vText.heatDestratify),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(vText.heatHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
