import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/reverberation.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String soundFloorLabel(AppLocalizations pText, SoundFloor pFloor) => switch (pFloor) {
  SoundFloor.tiles => pText.soundFloorTiles,
  SoundFloor.parquet => pText.soundFloorParquet,
  SoundFloor.carpet => pText.soundFloorCarpet,
};

String soundCeilingLabel(AppLocalizations pText, SoundCeiling pCeiling) => switch (pCeiling) {
  SoundCeiling.plaster => pText.soundCeilingPlaster,
  SoundCeiling.wood => pText.soundCeilingWood,
  SoundCeiling.acoustic => pText.soundCeilingAcoustic,
};

/// Réverbération d'une grande pièce et panneaux acoustiques pour la calmer.
class ReverberationCalculator extends StatefulWidget {
  const ReverberationCalculator({super.key});

  @override
  State<ReverberationCalculator> createState() => _ReverberationCalculatorState();
}

class _ReverberationCalculatorState extends State<ReverberationCalculator> {
  var _lengthMm = 8000;
  var _widthMm = 6000;
  var _heightMm = 5000;
  var _floor = SoundFloor.parquet;
  var _ceiling = SoundCeiling.plaster;
  var _furnished = true;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planReverb(
      pLengthMm: _lengthMm,
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pFloor: _floor,
      pCeiling: _ceiling,
      pFurnished: _furnished,
    );
    String vSeconds(double pValue) => formatDecimal((pValue * 10).round() / 10);

    return Scaffold(
      appBar: AppBar(title: Text(vText.reverbTitle)),
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
                  BigFigure(vText.reverbSeconds(vSeconds(vPlan.seconds))),
                  if (vPlan.panels == 0)
                    IconLine(
                      Icons.check_circle_outline,
                      vText.reverbFine(vSeconds(comfortableReverbSeconds)),
                    )
                  else ...[
                    IconLine(
                      Icons.graphic_eq,
                      vText.reverbTooLong(vSeconds(comfortableReverbSeconds)),
                      color: vTheme.colorScheme.error,
                    ),
                    IconLine(
                      Icons.view_module_outlined,
                      vText.reverbPanels(
                        vPlan.panels,
                        formatDecimal((vPlan.panels * acousticPanelM2 * 10).round() / 10),
                      ),
                    ),
                  ],
                  Text(vText.reverbHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<SoundFloor>(
            initialValue: _floor,
            decoration: InputDecoration(labelText: vText.reverbFloor),
            items: [
              for (final vFloor in SoundFloor.values)
                DropdownMenuItem(value: vFloor, child: Text(soundFloorLabel(vText, vFloor))),
            ],
            onChanged: (pFloor) => setState(() => _floor = pFloor!),
          ),
          DropdownButtonFormField<SoundCeiling>(
            initialValue: _ceiling,
            decoration: InputDecoration(labelText: vText.reverbCeiling),
            items: [
              for (final vCeiling in SoundCeiling.values)
                DropdownMenuItem(value: vCeiling, child: Text(soundCeilingLabel(vText, vCeiling))),
            ],
            onChanged: (pCeiling) => setState(() => _ceiling = pCeiling!),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.reverbFurnished),
            value: _furnished,
            onChanged: (pValue) => setState(() => _furnished = pValue),
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
